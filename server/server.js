const express = require('express')
const app = express()
const PORT = process.env.PORT || '4040';
const fs = require('node:fs');
const execSync = require('child_process').execSync;

app.get('/metrics', (req, res) => {

    const output = execSync('ie --manifest ./ie/cluster.yml', { encoding: 'utf-8' });  
    console.log('Output was:\n', output);
    const data = fs.readFileSync('./public/metrics.prom')
    res.set('Content-Type', 'text/plain')
    res.send(data)
})

app.listen(PORT, () => {
    console.log(`carbon-hack-24 listening on: ${PORT}`)
})