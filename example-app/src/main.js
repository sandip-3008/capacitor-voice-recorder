import { CapacitorVoiceRecorder } from '@lgicc/capacitor-voice-recorder';

const currentStatusEl = document.getElementById('🪪');
const canvasEl = document.getElementById('🖼️');


const ctx = canvasEl.getContext('2d');
const waveformOptions = {
    barWidth: 4,
    barSpacing: 6,
};


let isRecording = true;
let animFrame = null;
const centerY = canvasEl.height / 2;
const { barWidth, barSpacing } = waveformOptions;
const barCount = Math.floor(canvasEl.width / (barWidth + barSpacing)); // Dynamic number of bars

async function refreshStatus() {
    const {status} = await CapacitorVoiceRecorder.getCurrentStatus();
    currentStatusEl.innerHTML = status;
}


(async () => {
    await refreshStatus();
})();

function resizeCanvas() {
    const displayWidth = Math.floor(canvasEl.parentElement.clientWidth);
    console.log(displayWidth);

    canvasEl.width = displayWidth;
    canvasEl.height = 50;
}

window.addEventListener('resize', resizeCanvas);
resizeCanvas();

window.startRecording = async () => {
    try {
        const res = await CapacitorVoiceRecorder.requestPermission()
        const recording = await CapacitorVoiceRecorder.startRecording();
        isRecording = true;
        draw();

        let threshold = 0;

        CapacitorVoiceRecorder.addListener('frequencyData', ({base64}) => {
            const data = new Uint8Array(atob(base64).split('').map(c => c.charCodeAt(0)));
            const sum = data.reduce((sum, value) => sum + value, 0);
            const avg = sum / data.length;
            const rms = Math.sqrt(avg);

            let decibleValue = rms * 10;
            targetDataset.shift();
            if(decibleValue > threshold) {
                targetDataset.push(decibleValue);
            } else {
                targetDataset.push(5);
            }
        });

        await refreshStatus();
        console.log(res);
    } catch (e) {
        console.error(e)
    }
}

window.stopRecording = async () => {
    try {
        // retrieving audio data
        const result = await CapacitorVoiceRecorder.stopRecording();
        await CapacitorVoiceRecorder.removeAllListeners();
        isRecording = false;
        await refreshStatus();

        // parsing the data to a Uint8Array
        const data = new Uint8Array(atob(result.base64).split('').map(c => c.charCodeAt(0)));
        // now for example we can play the recorded audio
        const audioBlob = new Blob([data], { type: 'audio/wav' });
        const audioUrl = URL.createObjectURL(audioBlob);
        const audio = new Audio(audioUrl);

        const formData = new FormData();
        formData.append('audio', audioBlob, 'audio.wav');

        // test audio data
        fetch('http://localhost:3000',{
            method: 'POST',
            body: formData,
        })

        console.log('playing audio');
        audio.play().catch(error => {
            console.error('Audio playback failed:', error);
        });
        audio.onended = () => {
            console.log('Audio has finished playing');
        };
        audio.onerror = (err) => {
            console.error('Error playing audio:', err);
        };
    } catch (error) {
        console.log(error);
    }
}

window.requestPermission = async () => {
    try {
        const res = await CapacitorVoiceRecorder.requestPermission();
        await refreshStatus();
        console.log(res);
    } catch (e) {
        console.error(e)
    }
}



let dataset = [];
let targetDataset = [];
let defaultHeight = 5;

while (barCount > dataset.length) {
    dataset.push(defaultHeight);
    targetDataset.push(defaultHeight);
}

const draw = () => {
    if (!isRecording) {
        cancelAnimationFrame(animFrame);
        return;
    }

    if (!canvasEl) {
        return;
    }
    ctx.clearRect(0, 0, canvasEl.width, canvasEl.height);
    ctx.fillStyle = '#53cd57';

    const barWidth = 5;
    const spacing = (canvasEl.width - (barCount * barWidth)) / (barCount + 1);
    const centerY = canvasEl.height / 2;

    for (let i = 0; i < barCount; i++) {
        const x = spacing + (i * (barWidth + spacing));
        let height = dataset[i];

        if (height <= defaultHeight) {
            height = defaultHeight;
        }
        const y = centerY - height / 2;

        ctx.beginPath();
        ctx.roundRect(x, y, barWidth, height, 5);
        ctx.fill();

        if (dataset[i] < targetDataset[i]) {
            dataset[i] += (targetDataset[i] - dataset[i]) * 0.1; // Adjust the growth speed as needed
        } else if (dataset[i] > targetDataset[i]) {
            dataset[i] -= (dataset[i] - targetDataset[i]) * 0.1; // Adjust the shrink speed as needed
        }
    }

    animFrame = requestAnimationFrame(draw);
};