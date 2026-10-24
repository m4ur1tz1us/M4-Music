using System;
using System.IO;
using System.Text;
using System.Security.Cryptography;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Imaging;

internal static class CoverArt
{
    private const int MaxTag=16*1024*1024,MaxImage=8*1024*1024;
    private static int Size(byte[] b,int at,bool sync,int count)
    {
        long n=0;
        for(int i=0;i<count;i++) { if(sync&&b[at+i]>127)return -1;n=(n<<(sync?7:8))+b[at+i]; }
        return n>Int32.MaxValue?-1:(int)n;
    }
    private static byte[] Unsync(byte[] b)
    {
        using(MemoryStream m=new MemoryStream())
        {
            for(int i=0;i<b.Length;i++){m.WriteByte(b[i]);if(b[i]==255&&i+1<b.Length&&b[i+1]==0)i++;}
            return m.ToArray();
        }
    }
    private static byte[] Slice(byte[] b,int at,int length)
    { byte[] result=new byte[length];Buffer.BlockCopy(b,at,result,0,length);return result; }
    private static byte[] Picture(byte[] data,bool old,out int type)
    {
        type=-1;if(data.Length<6)return null;
        int encoding=data[0],at=1;
        if(encoding>3)return null;
        if(old) { string format=Encoding.ASCII.GetString(data,1,3);if(format!="PNG"&&format!="JPG")return null;at=4; }
        else
        {
            int end=Array.IndexOf(data,(byte)0,at);if(end<0)return null;
            string mime=Encoding.ASCII.GetString(data,at,end-at).ToLowerInvariant();
            if(mime!="image/png"&&mime!="image/jpeg"&&mime!="image/jpg")return null;at=end+1;
        }
        if(at>=data.Length)return null;type=data[at++];
        int unit=encoding==1||encoding==2?2:1;
        bool terminated=false;
        while(at+unit<=data.Length)
        {
            bool zero=data[at]==0&&(unit==1||data[at+1]==0);at+=unit;
            if(zero){terminated=true;break;}
        }
        if(!terminated||at>=data.Length||data.Length-at>MaxImage)return null;
        byte[] image=Slice(data,at,data.Length-at);
        bool png=image.Length>8&&image[0]==137&&image[1]==80&&image[2]==78&&image[3]==71;
        bool jpg=image.Length>3&&image[0]==255&&image[1]==216&&image[2]==255;
        return png||jpg?image:null;
    }
    public static byte[] Read(string path)
    {
        using(FileStream f=new FileStream(path,FileMode.Open,FileAccess.Read,FileShare.ReadWrite))
        {
            byte[] header=new byte[10];if(f.Read(header,0,10)!=10||Encoding.ASCII.GetString(header,0,3)!="ID3")return null;
            int version=header[3];if(version<2||version>4)return null;
            int length=Size(header,6,true,4);if(length<=0||length>MaxTag||length>f.Length-10)return null;
            if(version==2&&(header[5]&64)!=0)return null;
            byte[] tag=new byte[length];int read=0;
            while(read<length){int n=f.Read(tag,read,length-read);if(n==0)return null;read+=n;}
            bool unsync=(header[5]&128)!=0;
            if(unsync&&version<4)tag=Unsync(tag);
            int at=0;
            if(version>=3&&(header[5]&64)!=0)
            { int extension=Size(tag,0,version==4,4);if(extension<0)return null;at=version==3?extension+4:extension;if(at>tag.Length)return null; }
            byte[] fallback=null;int frameHeader=version==2?6:10;
            while(at<=tag.Length-frameHeader)
            {
                int idLength=version==2?3:4;
                string id=Encoding.ASCII.GetString(tag,at,idLength);if(tag[at]==0)break;
                int size=Size(tag,at+idLength,version==4,version==2?3:4);
                if(size<=0||size>tag.Length-at-frameHeader)break;
                int flags=version==2?0:tag[at+9];
                bool unsupported=version==3?(flags&224)!=0:version==4?(flags&77)!=0:false;
                if((id=="APIC"||id=="PIC")&&!unsupported&&size<=MaxImage+1024)
                {
                    byte[] data=Slice(tag,at+frameHeader,size);
                    if(version==4&&(unsync||(flags&2)!=0))data=Unsync(data);
                    int type;byte[] image=Picture(data,version==2,out type);
                    if(image!=null){if(type==3)return image;if(fallback==null)fallback=image;}
                }
                at+=frameHeader+size;
            }
            return fallback;
        }
    }
    public static string Extract(string path,string cache)
    {
        try
        {
            byte[] raw=Read(path);if(raw==null)return "";
            string name;using(SHA256 hash=SHA256.Create())name=BitConverter.ToString(hash.ComputeHash(raw)).Replace("-","").ToLowerInvariant()+".png";
            Directory.CreateDirectory(cache);string output=Path.Combine(cache,name);if(File.Exists(output))return name;
            BitmapImage bitmap=new BitmapImage();
            using(MemoryStream stream=new MemoryStream(raw))
            {
                BitmapDecoder info=BitmapDecoder.Create(stream,BitmapCreateOptions.DelayCreation,BitmapCacheOption.None);
                int iw=info.Frames[0].PixelWidth,ih=info.Frames[0].PixelHeight;
                if(iw<=0||ih<=0||iw>16000||ih>16000||(long)iw*ih>64000000)return "";
                stream.Position=0;bitmap.BeginInit();bitmap.CacheOption=BitmapCacheOption.OnLoad;
                if(iw>=ih)bitmap.DecodePixelWidth=256;else bitmap.DecodePixelHeight=256;
                bitmap.StreamSource=stream;bitmap.EndInit();bitmap.Freeze();
            }
            if(bitmap.PixelWidth<=0||bitmap.PixelHeight<=0)return "";
            double scale=Math.Min(256.0/bitmap.PixelWidth,256.0/bitmap.PixelHeight);
            double w=bitmap.PixelWidth*scale,h=bitmap.PixelHeight*scale;
            DrawingVisual visual=new DrawingVisual();using(DrawingContext dc=visual.RenderOpen())
            { dc.DrawRectangle(Brushes.Black,null,new Rect(0,0,256,256));dc.DrawImage(bitmap,new Rect((256-w)/2,(256-h)/2,w,h)); }
            RenderTargetBitmap target=new RenderTargetBitmap(256,256,96,96,PixelFormats.Pbgra32);target.Render(visual);
            PngBitmapEncoder encoder=new PngBitmapEncoder();encoder.Frames.Add(BitmapFrame.Create(target));
            using(FileStream file=new FileStream(output+".tmp",FileMode.Create,FileAccess.Write))encoder.Save(file);
            File.Move(output+".tmp",output);return name;
        }
        catch { return ""; } // Cover errors must never break audio playback.
    }
}
