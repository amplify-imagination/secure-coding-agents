// probe from INSIDE the no-egress network: model should answer, the open internet should not.
const http = require("http"), https = require("https");
const G="\x1b[32m", R="\x1b[31m", D="\x1b[90m", Z="\x1b[0m";
function hit(label, mod, opts){return new Promise(res=>{
  const req = mod.request({...opts, timeout:4000}, r=>{r.resume(); res({label, ok:true, code:r.statusCode});});
  req.on("error", e=>res({label, ok:false, err:e.code||"blocked"}));
  req.on("timeout", ()=>{req.destroy(); res({label, ok:false, err:"timeout"});});
  req.end();
});}
(async()=>{
  const model = await hit("the model (via relay)", http, {host:"cage-modelproxy", port:1234, path:"/v1/models"});
  const net   = await hit("the open internet  ", https, {host:"example.com", port:443, path:"/"});
  const gh    = await hit("github.com         ", https, {host:"api.github.com", port:443, path:"/"});
  const line=(r)=> r.ok ? `${G}  reachable   ${Z} ${D}HTTP ${r.code}${Z}` : `${R}  blocked     ${Z} ${D}${r.err}${Z}`;
  console.log("");
  console.log(`  ${model.label}  ${line(model)}`);
  console.log(`  ${net.label}    ${line(net)}`);
  console.log(`  ${gh.label}    ${line(gh)}`);
  console.log("");
})();
