import './App.css';
import React, {useEffect, useState} from "react";
import useWebSocket from "react-use-websocket";
import ReactAudioSpectrum from "react-audio-spectrum";

const WS_URL = "wss://radio-api.origincode.me/";
const AUDIO_URL = "https://radio-raw.origincode.me/";

function Info() {
    const {lastMessage} = useWebSocket(WS_URL, {
        heartbeat: {
            message: "ping", returnMessage: "pong", timeout: 30000, interval: 5000,
        }, shouldReconnect: () => true,
    });
    let lastMessageData = lastMessage ? JSON.parse(lastMessage.data) : null;
    let current = lastMessageData ? (Object.keys(lastMessageData.current).length !== 0 ? lastMessageData.current : null) : null;
    let next = lastMessageData ? (Object.keys(lastMessageData.next).length !== 0 ? lastMessageData.next : null) : null;
    useEffect(() => {
        if ("mediaSession" in navigator) {
            navigator.mediaSession.metadata = new MediaMetadata({
                title: current ? current.Title : "FrontieRadio", artist: current ? current.Artist : "Unknown",
            });
        }
    }, [lastMessage, current]);

    const infoContent = (infoData, placeholder) => {
        let text = infoData ? (
            `${infoData.Artist ? infoData.Artist : "Unknown"}
            - ${infoData.Title ? infoData.Title : "Unknown"}`
        ) : placeholder;
        return (
            <div className="content">
                {text}
            </div>
        )
    }

    return (
        <div className="info">
            <div className="flex-item">
                <div className="header">
                    NOW PLAYING:
                </div>
                {infoContent(current, "No song playing")}
            </div>
            <div className="flex-item">
                <div className="header">
                    NEXT SONG:
                </div>
                {infoContent(next, "No next song")}
            </div>
        </div>
    )
}

function VolumeSlider({audio}) {
    const [volume, setVolume] = useState(Math.round(audio.volume * 100));
    useEffect(() => {
        audio.volume = volume / 100;
    }, [audio, volume]);

    return (
        <div className="flex-item volume">
            <div className="header">
                VOLUME
            </div>
            <input type="range" min={0} max={100} step={1} value={volume} title={volume + "%"}
                   onInput={event => {
                       setVolume(parseInt(event.target.value));
                   }}
                   onWheel={event => {
                       let deltaVolume = event.deltaY > 0 ? -1 : 1;
                       setVolume(Math.min(100, Math.max(0, volume + deltaVolume)));
                   }}
            />
        </div>
    );
}

function Player() {
    const [audio] = useState(new Audio(AUDIO_URL));
    const [playing, setPlaying] = useState(false);
    const playOrPause = () => setPlaying(!playing);
    audio.addEventListener("ended", () => setPlaying(false));
    audio.addEventListener("pause", () => setPlaying(false));
    audio.addEventListener("loadeddata", () => {
        if (playing) {
            audio.play();
        }
    });
    audio.crossOrigin = "anonymous";
    audio.preload = "none";
    if ("mediaSession" in navigator) {
        navigator.mediaSession.setActionHandler("pause", () => setPlaying(false));
        navigator.mediaSession.setActionHandler("play", () => setPlaying(true));
    }
    useEffect(() => {
        if (playing) {
            audio.load();
            if ("mediaSession" in navigator) {
                navigator.mediaSession.playbackState = "playing";
            }
        } else {
            audio.pause();
            audio.currentTime = 0;
            if ("mediaSession" in navigator) {
                navigator.mediaSession.playbackState = "paused";
            }
        }
    }, [audio, playing]);

    let style = window.getComputedStyle(document.body);
    let titleColor = style.getPropertyValue("--title-color");
    let textColor = style.getPropertyValue("--text-color");

    return (
        <>
            <button onClick={playOrPause}>{playing ? "Stop" : "Play"}</button>
            <VolumeSlider audio={audio}/>
            <button onClick={playOrPause}>
                <ReactAudioSpectrum
                    id="audio-canvas"
                    height={100}
                    width={317}
                    meterWidth={5}
                    meterColor={[{stop: 0, color: titleColor},]}
                    capColor={textColor}
                    gap={3}
                    audioEle={audio}/>
            </button>
        </>
    )
}

function App() {
    return (
        <div className="App">
            <main>
                <header className="header">
                    FrontieRadio :: ON AIR
                </header>
                <Info/>
                <Player/>
            </main>
            <footer className="flex-item about">
                <a href="https://radio-raw.origincode.me/">Raw</a>
                <a href="https://factoria.origincode.me/OriginCode/frontieradio">Factoria</a>
                <a href="https://github.com/OriginCode/frontieradio">GitHub</a>
            </footer>
        </div>
    );
}

export default App;
