BASE = '''<html><head><style>
@font-face{font-family:V;src:url(Vazirmatn-Black.ttf);font-weight:900}
*{margin:0;box-sizing:border-box}
body{width:1290px;height:2796px;overflow:hidden;position:relative;font-family:V,'Noto Color Emoji',sans-serif;font-weight:900;color:#fff;background:#2a1d5e}
.bg{position:absolute}
.fadeT{position:absolute;left:0;right:0;height:500px}
.fadeB{position:absolute;left:0;right:0;bottom:0;height:620px;background:linear-gradient(#2a1d5e00,#2a1d5ecc 45%,#24184f 100%)}
h1{text-align:center;font-size:150px;line-height:1.02;color:#FFD43B;
 -webkit-text-stroke:16px #2a1d5e;paint-order:stroke fill;text-shadow:0 14px 0 #140f2e;letter-spacing:-2px}
.sub{margin-top:28px;text-align:center;font-size:66px;color:#fff;-webkit-text-stroke:10px #2a1d5e;paint-order:stroke fill;text-shadow:0 6px 0 #140f2e}
.phone{position:absolute;background:#0d0a1f;border-radius:80px;padding:24px;box-shadow:0 30px 60px #000a,0 0 0 8px #ffffff30}
.phone img{display:block;width:100%;height:100%;border-radius:58px;object-fit:cover}
.head{position:absolute;left:40px;right:40px;top:140px;text-align:center}
.bubble{position:absolute;background:#fff;color:#2a1d5e;border:8px solid #2a1d5e;border-radius:60px;padding:22px 44px;font-size:70px;box-shadow:0 14px 0 #2a1d5e;white-space:nowrap}
.langs{position:absolute;bottom:250px;left:0;right:0;text-align:center;font-size:58px;color:#fff}
.brand{position:absolute;bottom:80px;left:0;right:0;text-align:center;font-size:130px;color:#fff;letter-spacing:-1px}
.brand span{color:#FFD43B}
.chip{display:inline-block;margin:14px;padding:18px 46px;border-radius:70px;background:#fff;color:#2a1d5e;font-size:78px;border:8px solid #2a1d5e;box-shadow:0 12px 0 #2a1d5e}
</style></head><body>
<img class=bg id=bg src="{img}" style="top:{top}px;left:{left}px;width:{width}px;{bgstyle}">
<div class=fadeT id=ft style="top:{fadetop}px"></div>
<div class=fadeB></div>
{content}
<div class=langs dir=ltr><bdi>English</bdi> · <bdi>فارسی</bdi> · <bdi>العربية</bdi> · <bdi>Русский</bdi> · <bdi>Türkçe</bdi></div>
<div class=brand>Dorehami<span>!</span></div>
<script>
const im=document.getElementById('bg');
im.onload=()=>{const c=document.createElement('canvas');c.width=im.naturalWidth;c.height=6;const x=c.getContext('2d');x.drawImage(im,0,0,im.naturalWidth,6,0,0,im.naturalWidth,6);
 const d=x.getImageData(0,0,c.width,1).data;let r=0,g=0,b=0,n=0;for(let i=0;i<d.length;i+=4){r+=d[i];g+=d[i+1];b+=d[i+2];n++}
 const col=`rgb(${r/n|0},${g/n|0},${b/n|0})`;document.body.style.background=col;
 document.getElementById('ft').style.background=`linear-gradient(${col},${col.replace('rgb','rgba').replace(')',',0)')})`;document.body.dataset.ready=1}
</script></body></html>'''
P = {
 'p2': dict(img='img8.webp', top=571, left=-96, width=1483, fadetop=571, bgstyle='', content='''
<div class=head><h1>Act it out!</h1><div class=sub>Classic Pantomime with friends</div></div>
<div class=phone style="left:70px;top:660px;width:430px;height:930px;transform:rotate(-6deg)"><img src="04_classic.png"></div>
<div class=bubble style="left:560px;top:1480px;transform:rotate(-5deg)">I know! I know!</div>'''),
 'p3': dict(img='img7.webp', top=571, left=-96, width=1483, fadetop=571, bgstyle='', content='''
<div class=head><h1>Fun for the<br>whole family</h1><div class=sub>Teams, timers &amp; hundreds of words</div></div>
<div class=phone style="left:50px;top:760px;width:480px;height:1040px;transform:rotate(-5deg)"><img src="02_setup.png"></div>'''),
 'p4': dict(img='img6.webp', top=571, left=-96, width=1483, fadetop=571, bgstyle='', content='''
<div class=head><h1>Play in<br>5 languages</h1></div>
<div style="position:absolute;top:640px;left:30px;right:30px;text-align:center">
<span class=chip>English</span><span class=chip>فارسی</span><span class=chip>العربية</span><br><span class=chip>Русский</span><span class=chip>Türkçe</span></div>'''),
 'p5': dict(img='img5.webp', top=861, left=0, width=1290, fadetop=820, bgstyle='filter:blur(5px) brightness(.75)', content='''
<div class=head><h1>Snap a<br>group photo!</h1><div class=sub>Fun frames to save &amp; share</div></div>
<div class=phone style="left:300px;top:820px;width:690px;height:1500px;transform:rotate(4deg)"><img src="frame_polaroid.png"></div>
<div class=bubble style="left:60px;top:1950px;transform:rotate(-7deg)">Say cheese! 📸</div>'''),
}
for k,v in P.items():
    h=BASE
    for kk,vv in v.items(): h=h.replace('{'+kk+'}',str(vv))
    open(k+'.html','w').write(h)
