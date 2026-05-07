async function run() {
  const tokenRes = await fetch('http://localhost:18080/auth/realms/camunda-platform/protocol/openid-connect/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'client_credentials',
      client_id: 'incident-reporter-app',
      client_secret: 'EioCAn7uWXBFDiOLgVPi87GaBjtcIPyJ',
      audience: 'orchestration-api'
    })
  });
  const token = (await tokenRes.json()).access_token;
  const exec = require('child_process').execSync;
  try {
    const cmd = `curl -v -X POST http://localhost:8080/v2/deployments -H "Authorization: Bearer ${token}" -F "resources=@../../../urgence-process.bpmn" -F "resources=@../../../selection-hopital.dmn" -F "resources=@../../../affectation-ambulance.dmn"`;
    const out = exec(cmd);
    console.log('Output:', out.toString());
  } catch(e) {
    console.log('Error:', e.stdout ? e.stdout.toString() : e.message);
    console.log('Stderr:', e.stderr ? e.stderr.toString() : '');
  }
}
run().catch(console.error);
