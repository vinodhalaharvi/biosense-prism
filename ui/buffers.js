window.ecgBuffer = [];
window.ppgBuffer = [];

function addToBuffer(type, value) {
  const buf = type === 'ecg' ? window.ecgBuffer : window.ppgBuffer;
  buf.push(value);
  if (buf.length > 500) buf.shift();
  drawWaveform(type);
}

function drawWaveform(type) {
  const canvas = document.getElementById(type + "-canvas");
  if (!canvas) return;
  const ctx = canvas.getContext("2d");
  ctx.clearRect(0,0,canvas.width, canvas.height);
  const buf = type === 'ecg' ? window.ecgBuffer : window.ppgBuffer;
  ctx.beginPath();
  buf.forEach((v,i)=>{
    const x = i * canvas.width / buf.length;
    const y = canvas.height/2 - v*50;
    if(i===0) ctx.moveTo(x,y); else ctx.lineTo(x,y);
  });
  ctx.stroke();
}
