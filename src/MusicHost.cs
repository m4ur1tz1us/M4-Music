// M4 | Music v0.1. Native Windows MP3 playback; no conversion or third-party codec DLL.
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Windows.Media;
using System.Windows.Threading;

[assembly:System.Reflection.AssemblyTitle("M4 | Music")]
[assembly:System.Reflection.AssemblyVersion("0.7.0.0")]
[assembly:System.Reflection.AssemblyFileVersion("0.7.0.0")]

internal sealed class Audio : IDisposable
{
    public static bool Supported(string path)
    {
        string ext=Path.GetExtension(path);
        return String.Equals(ext,".mp3",StringComparison.OrdinalIgnoreCase)||String.Equals(ext,".wav",StringComparison.OrdinalIgnoreCase);
    }
    private MediaPlayer player;
    private bool ended;
    private Exception mediaError;
    public bool Opened { get; private set; }
    public bool Playing { get; private set; }
    public static void Wait(int milliseconds)
    {
        DispatcherFrame frame=new DispatcherFrame();
        DispatcherTimer timer=new DispatcherTimer(DispatcherPriority.Background);
        timer.Interval=TimeSpan.FromMilliseconds(milliseconds);
        timer.Tick+=delegate { timer.Stop();frame.Continue=false; };
        timer.Start();Dispatcher.PushFrame(frame);
    }
    public void Open(string path, int volume)
    {
        Dispose();
        if(!File.Exists(path) || !Supported(path) || path.Contains("\""))
            throw new IOException("Keine gueltige lokale MP3-/WAV-Datei.");
        bool ready=false;mediaError=null;ended=false;player=new MediaPlayer();
        player.Volume=Math.Max(0,Math.Min(100,volume))/100.0;
        player.MediaOpened+=delegate { ready=true; };
        player.MediaFailed+=(sender,e)=> { mediaError=e.ErrorException; };
        player.MediaEnded+=delegate { ended=true; };
        try
        {
            player.Open(new Uri(Path.GetFullPath(path),UriKind.Absolute));
            Stopwatch timeout=Stopwatch.StartNew();
            while(!ready&&mediaError==null&&timeout.ElapsedMilliseconds<4000)Wait(20);
            if(mediaError!=null)throw new IOException("Windows kann diese MP3 nicht oeffnen.",mediaError);
            if(!ready||!player.NaturalDuration.HasTimeSpan||!player.HasAudio)throw new IOException("MP3 hat keine lesbare Audiospur.");
            Opened=true;if(Length<=0)throw new IOException("MP3 hat keine lesbare Dauer.");
        }
        catch { Dispose();throw; }
    }
    public void Volume(int value) { if(Opened)player.Volume=Math.Max(0,Math.Min(100,value))/100.0; }
    public int Position { get { return Opened ? (int)player.Position.TotalMilliseconds : 0; } }
    public int Length { get { return Opened&&player.NaturalDuration.HasTimeSpan ? (int)player.NaturalDuration.TimeSpan.TotalMilliseconds : 0; } }
    public void Seek(int milliseconds)
    {
        if(!Opened)return;
        player.Position=TimeSpan.FromMilliseconds(Math.Max(0,Math.Min(Math.Max(0,Length-100),milliseconds)));
        ended=false;
    }
    public string Mode { get { return !Opened?"closed":ended?"stopped":Playing?"playing":"paused"; } }
    public void Gate(bool play)
    {
        if(mediaError!=null)throw new IOException("MP3-Wiedergabefehler.",mediaError);
        if(!Opened)return;
        if(play && !Playing) { player.Play();Playing=true; }
        if(!play && Playing) { player.Pause();Playing=false; }
    }
    public void Dispose()
    {
        if(player!=null) { player.Close();player=null; }
        Opened=false;Playing=false;mediaError=null;ended=false;
    }
}

internal static class Protocol
{
    public static string Escape(string value) { return (value ?? "").Replace("%","%25").Replace("\r","%0D").Replace("\n","%0A").Replace("=","%3D"); }
    public static string Unescape(string value)
    {
        return System.Text.RegularExpressions.Regex.Replace(value,"%([0-9a-fA-F]{2})",m=>((char)Convert.ToByte(m.Groups[1].Value,16)).ToString());
    }
    public static Dictionary<string,string> Read(string path)
    {
        Dictionary<string,string> values=new Dictionary<string,string>();
        using(FileStream f=new FileStream(path,FileMode.Open,FileAccess.Read,FileShare.ReadWrite|FileShare.Delete))
        using(StreamReader reader=new StreamReader(f,Encoding.UTF8,true))
        {
            if(f.Length>16384)throw new IOException("Steuerdatei zu gross.");
            string line;while((line=reader.ReadLine())!=null) { int at=line.IndexOf('=');if(at>0)values[line.Substring(0,at)]=Unescape(line.Substring(at+1)); }
        }
        return values;
    }
    public static void Write(string path, Dictionary<string,string> values)
    {
        string temporary=path+".tmp";
        using(StreamWriter writer=new StreamWriter(temporary,false,new UTF8Encoding(false)))
            foreach(var pair in values)writer.WriteLine(pair.Key+"="+Escape(pair.Value));
        if(File.Exists(path))File.Replace(temporary,path,null);else File.Move(temporary,path);
    }
    public static int Number(Dictionary<string,string> values,string key,int fallback)
    {
        string raw;int parsed;return values.TryGetValue(key,out raw)&&Int32.TryParse(raw,NumberStyles.Integer,CultureInfo.InvariantCulture,out parsed)?parsed:fallback;
    }
    public static string Text(Dictionary<string,string> values,string key,string fallback)
    { string found;return values.TryGetValue(key,out found)?found:fallback; }
}

internal sealed class Host : IDisposable
{
    private readonly string root;
    private readonly Audio audio=new Audio();
    private readonly Random random=new Random();
    private List<string> files=new List<string>();
    private readonly Stack<string> history=new Stack<string>();
    private Process game;
    private int index=-1,step,scan=-1,volume=35,sequence=-1,seekSequence;
    private string session="",error="",track="",savedSettings="",cover="";
    private bool wanted=true,shuffle,active,combat=true,connected,gate;
    private DateTime lastControl=DateTime.MinValue,lastStatus=DateTime.MinValue;
    private DateTime readyAt=DateTime.MaxValue,fadeStart=DateTime.MaxValue;
    private bool initialSelection=true;
    private int effectiveVolume;
    private double musicMix;
    private DateTime lastEnvelope=DateTime.UtcNow;
    public Host(string folder) { root=Path.GetFullPath(folder);Directory.CreateDirectory(Path.Combine(root,"Music")); }
    private void Log(string message)
    {
        try { string path=Path.Combine(root,"host.log");if(File.Exists(path)&&new FileInfo(path).Length>512000)File.Move(path,path+"."+DateTime.UtcNow.Ticks+".old");File.AppendAllText(path,DateTime.UtcNow.ToString("o")+" "+message+Environment.NewLine,Encoding.UTF8); } catch { }
    }
    private void Fail(Exception exception) { error=exception.Message;Log(error);try { audio.Gate(false); }catch { audio.Dispose(); } }
    private bool OpenIndex(int requested,int direction)
    {
        audio.Dispose();track="";cover="";
        if(files.Count==0){index=-1;return false;}
        for(int attempt=0;attempt<files.Count;attempt++)
        {
            index=((requested+direction*attempt)%files.Count+files.Count)%files.Count;
            try { audio.Open(files[index],0);musicMix=0;lastEnvelope=DateTime.UtcNow;effectiveVolume=0;track=Path.GetFileNameWithoutExtension(files[index]);cover=CoverArt.Extract(files[index],Path.Combine(root,"CoverCache"));error="";return true; }
            catch(Exception ex) { Log("Uebersprungen: "+Path.GetFileName(files[index])+" / "+ex.Message);error="MP3 nicht abspielbar: "+Path.GetFileName(files[index]); }
        }
        index=-1;return false;
    }
    private void Scan()
    {
        string current=index>=0&&index<files.Count?files[index]:null;
        try { files=Directory.GetFiles(Path.Combine(root,"Music"),"*",SearchOption.TopDirectoryOnly).Where(Audio.Supported).OrderBy(p=>Path.GetFileName(p),StringComparer.OrdinalIgnoreCase).ToList(); }
        catch(Exception ex){Fail(ex);return;}
        history.Clear();
        int retained=current==null?-1:files.FindIndex(p=>String.Equals(p,current,StringComparison.OrdinalIgnoreCase));
        if(retained>=0&&audio.Opened){index=retained;return;}
        int first=0;
        if(shuffle&&files.Count>0)
        {
            string previous="";try{previous=File.ReadAllText(Path.Combine(root,"last-start.txt"),Encoding.UTF8);}catch(IOException){}
            List<int> candidates=Enumerable.Range(0,files.Count).Where(i=>!initialSelection||!String.Equals(files[i],previous,StringComparison.OrdinalIgnoreCase)).ToList();
            if(candidates.Count>0)first=candidates[random.Next(candidates.Count)];else first=random.Next(files.Count);
        }
        if(OpenIndex(first,1)&&initialSelection)
        {
            File.WriteAllText(Path.Combine(root,"last-start.txt"),files[index],new UTF8Encoding(false));initialSelection=false;
        }
        if(files.Count==0)error="";
        Log("Musikordner eingelesen: "+files.Count+" MP3-/WAV-Dateien.");
    }
    private void Move(int direction)
    {
        if(files.Count==0)return;
        if(direction<0&&shuffle&&history.Count>0)
        {
            string previous=history.Pop();int found=files.IndexOf(previous);if(found>=0){OpenIndex(found,-1);return;}
        }
        if(index>=0&&index<files.Count&&direction>0){if(history.Count>1000)history.Clear();history.Push(files[index]);}
        int next=index<0?0:index+direction;
        if(shuffle&&direction>0&&files.Count>1)next=(index+1+random.Next(files.Count-1))%files.Count;
        OpenIndex(next,direction);
    }
    private void SaveSettings()
    {
        string key=volume+":"+shuffle+":"+wanted;if(savedSettings==key)return;
        Protocol.Write(Path.Combine(root,"Settings.ini"),new Dictionary<string,string>{{"volume",volume.ToString()},{"shuffle",shuffle?"1":"0"},{"wanted",wanted?"1":"0"}});savedSettings=key;
    }
    private void ReadControl()
    {
        Dictionary<string,string> values;
        try { values=Protocol.Read(Path.Combine(root,"control.ini")); } catch(IOException){return;}
        int seq=Protocol.Number(values,"seq",-1);
        if(seq<0||Protocol.Number(values,"complete",-2)!=seq||Protocol.Number(values,"version",0)!=1)return;
        string incoming=Protocol.Text(values,"session","");if(incoming.Length<3)return;
        if(session!=incoming){audio.Dispose();index=-1;active=false;initialSelection=true;readyAt=DateTime.MaxValue;fadeStart=DateTime.MaxValue;session=incoming;sequence=-1;step=0;scan=-1;seekSequence=0;Log("Neue Spielsitzung: "+session);}
        if(seq<=sequence)return;
        sequence=seq;lastControl=DateTime.UtcNow;connected=true;
        bool nextActive=Protocol.Number(values,"active",0)==1;
        if(nextActive&&!active)readyAt=DateTime.UtcNow.AddSeconds(5);
        if(!nextActive)readyAt=DateTime.MaxValue;
        active=nextActive;combat=Protocol.Number(values,"combat",1)!=0;
        wanted=Protocol.Number(values,"wanted",0)==1;shuffle=Protocol.Number(values,"shuffle",1)==1;
        int newVolume=Math.Max(0,Math.Min(100,Protocol.Number(values,"volume",35)));
        // Apply the combat/world gate BEFORE rescan or title navigation.
        gate=active&&!combat&&wanted&&DateTime.UtcNow>=readyAt;
        if(!active||!wanted){audio.Gate(false);musicMix=0;}
        volume=newVolume;
        int requestedScan=Protocol.Number(values,"scan",0);if(requestedScan!=scan){scan=requestedScan;Scan();}
        int requestedStep=Protocol.Number(values,"step",step);
        long delta=(long)requestedStep-step;
        if(Math.Abs(delta)>1000){error="Zu viele Titelbefehle in einer Nachricht.";}else
            for(int i=0;i<Math.Abs(delta);i++)Move(delta>0?1:-1);
        step=requestedStep;
        int seek=Protocol.Number(values,"seek_seq",0);
        if(seek>seekSequence)
        {
            if(Protocol.Number(values,"seek_step",Int32.MinValue)==step)audio.Seek(Protocol.Number(values,"seek_ms",0));
            seekSequence=seek;
        }
        SaveSettings();
    }
    private void Status(string mode)
    {
        if((DateTime.UtcNow-lastStatus).TotalMilliseconds<250)return;lastStatus=DateTime.UtcNow;
        Protocol.Write(Path.Combine(root,"status.ini"),new Dictionary<string,string>{
            {"version","1"},{"session",session},{"ack",sequence.ToString()},{"seek_ack",seekSequence.ToString()},{"track",track},{"error",error},
            {"mode",mode},{"position_ms",audio.Position.ToString()},{"duration_ms",audio.Length.ToString()},
            {"effective_volume",effectiveVolume.ToString()},
            {"cover",cover},
            {"music_mix",musicMix.ToString("F4",CultureInfo.InvariantCulture)},
            {"count",files.Count.ToString()},{"index",(index+1).ToString()},{"pid",Process.GetCurrentProcess().Id.ToString()},
            {"updated_utc",DateTime.UtcNow.ToString("o")}});
    }
    public void Run(bool testing)
    {
        if(!testing)
        {
            string expected=Path.GetFullPath(Path.Combine(root,"..","..","..","Palworld-Win64-Shipping.exe"));
            foreach(Process candidate in Process.GetProcessesByName("Palworld-Win64-Shipping"))
            { try { if(String.Equals(candidate.MainModule.FileName,expected,StringComparison.OrdinalIgnoreCase)){game=candidate;break;} } catch { } }
            if(game==null){Log("Palworld laeuft nicht; Audiobegleiter beendet.");return;}
        }
        Log("M4 | Music v0.7 gestartet.");DateTime started=DateTime.UtcNow;
        try
        {
            while(testing?(DateTime.UtcNow-started).TotalSeconds<90:!game.HasExited)
            {
                try
                {
                    ReadControl();
                    double age=(DateTime.UtcNow-lastControl).TotalSeconds;
                    connected=age<3;
                    gate=connected&&active&&!combat&&wanted&&DateTime.UtcNow>=readyAt;
                    double dt=Math.Max(0,Math.Min(.25,(DateTime.UtcNow-lastEnvelope).TotalSeconds));lastEnvelope=DateTime.UtcNow;
                    if(!connected||!active||!wanted||!audio.Opened)musicMix=0;
                    else musicMix=gate?Math.Min(1,musicMix+dt/3.0):Math.Max(0,musicMix-dt/1.5);
                    effectiveVolume=(int)Math.Round(volume*musicMix);audio.Volume(testing?0:effectiveVolume);
                    // The track keeps advancing only until its combat fade reaches silence.
                    audio.Gate(audio.Opened&&(gate||musicMix>0));
                    if(gate&&audio.Opened&&audio.Mode=="stopped")
                    { Move(1); }
                    string mode=!connected?"disconnected":!active?"world_paused":combat?(musicMix>0?"combat_fading":"combat_paused"):!wanted?"paused":!audio.Opened?(files.Count==0?"empty":"error"):DateTime.UtcNow<readyAt?"startup_delay":"playing";
                    Status(mode);
                    if((!connected&&(DateTime.UtcNow-started).TotalSeconds>45)&&!testing)break;
                }
                catch(Exception ex){Fail(ex);try{Status("error");}catch{}}
                Audio.Wait(100);
            }
        }
        finally { audio.Dispose();lastStatus=DateTime.MinValue;try{Status("closed");}catch{}Log("Audiobegleiter beendet."); }
    }
    public void Dispose(){audio.Dispose();if(game!=null)game.Dispose();}
}

internal static class Program
{
    [STAThread]
    private static int Main(string[] args)
    {
        string root=AppDomain.CurrentDomain.BaseDirectory;
        try
        {
            if(args.Length==3&&args[0]=="--cover-test")
            { Directory.CreateDirectory(args[2]);string coverName=CoverArt.Extract(args[1],args[2]);File.WriteAllText(Path.Combine(args[2],"result.txt"),coverName);return 0; }
            if(args.Length==3&&args[0]=="--self-test")return SelfTest(args[1],args[2]);
            bool testing=args.Length==2&&args[0]=="--test-root";
            if(testing)root=Path.GetFullPath(args[1]);
            string hash;using(SHA256 sha=SHA256.Create())hash=BitConverter.ToString(sha.ComputeHash(Encoding.UTF8.GetBytes(root.ToUpperInvariant()))).Replace("-","").Substring(0,24);
            bool created;using(Mutex mutex=new Mutex(true,"Local\\M4Music_"+hash,out created))
            { if(!created)return 0;try{using(Host host=new Host(root))host.Run(testing);}finally{mutex.ReleaseMutex();} }
            return 0;
        }
        catch(Exception ex){try{File.AppendAllText(Path.Combine(root,"host-fatal.log"),ex+Environment.NewLine);}catch{}return 1;}
    }
    private static int SelfTest(string source,string output)
    {
        Dictionary<string,string> result=new Dictionary<string,string>();
        try
        {
            using(Audio audio=new Audio())
            {
                audio.Open(source,0);int length=audio.Length;if(length<4000)throw new Exception("Test-MP3 zu kurz.");
                audio.Gate(true);Audio.Wait(700);int before=audio.Position;if(before<200)throw new Exception("MP3 spielt nicht.");
                audio.Gate(false);Audio.Wait(60);int paused=audio.Position;Audio.Wait(500);int still=audio.Position;
                if(Math.Abs(still-paused)>100)throw new Exception("Pause behaelt Position nicht.");
                audio.Gate(true);Audio.Wait(600);int resumed=audio.Position;
                if(resumed<paused+200)throw new Exception("Fortsetzen fehlgeschlagen.");
                audio.Volume(25);audio.Volume(0);audio.Gate(false);
                result["length_ms"]=length.ToString();result["before_pause_ms"]=before.ToString();result["paused_ms"]=paused.ToString();result["after_wait_ms"]=still.ToString();result["resumed_ms"]=resumed.ToString();
                result["mp3_play_pause_resume_volume"]="passed";
            }
            using(Audio audio=new Audio()) { try{audio.Open(source+".missing.mp3",0);throw new Exception("Fehlende Datei akzeptiert.");}catch(IOException){result["missing_file_rejected"]="passed";} }
            Protocol.Write(output,result);return 0;
        }
        catch(Exception ex){result["error"]=ex.ToString();Protocol.Write(output,result);return 2;}
    }
}
