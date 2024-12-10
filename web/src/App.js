import './App.css';
import React, {useEffect, useState} from "react";
import useWebSocket from "react-use-websocket";

function App() {
    const AUDIO_URL = "https://radio-raw.origincode.me/";
    const WS_URL = "wss://radio-api.origincode.me/";

    const [audio] = useState(new Audio(AUDIO_URL));
    const [playing, setPlaying] = useState(false);
    const playOrPause = () => setPlaying(!playing);
    audio.addEventListener("ended", () => setPlaying(false));
    audio.addEventListener("pause", () => setPlaying(false));
    navigator.mediaSession.setActionHandler("pause", () => setPlaying(false));
    navigator.mediaSession.setActionHandler("play", () => setPlaying(true));
    useEffect(() => {
            if (playing) {
                audio.play();
                audio.muted = false;
                navigator.mediaSession.playbackState = "playing";
            } else {
                audio.muted = true;
                navigator.mediaSession.playbackState = "paused";
            }
        },
        [audio, playing]
    );

    const {lastMessage} = useWebSocket(WS_URL,
        {
            heartbeat: {
                message: "ping",
                returnMessage: "pong",
                timeout: 30000,
                interval: 5000,
            },
            shouldReconnect: () => true,
        });
    let lastMessageData = lastMessage ? JSON.parse(lastMessage.data) : null;
    let current = lastMessageData ? (
        Object.keys(lastMessageData.current).length !== 0 ? lastMessageData.current : null
    ) : null;
    let next = lastMessageData ? (
        Object.keys(lastMessageData.next).length !== 0 ? lastMessageData.next : null
    ) : null;
    useEffect(() => {
        console.log(lastMessage);
        navigator.mediaSession.metadata = new MediaMetadata({
            title: current ? current.Title : "FrontieRadio",
            artist: current ? current.Artist : "Unknown",
        });
    }, [lastMessage, current]);

    return (
        <div className="App">
            <div className="main">
                <div className="info">
                    <div className="flex-item">
                        <div className="header">
                            NOW PLAYING:
                        </div>
                        <div className="content">
                            {current ?
                                `${current.Artist} - ${current.Title}`
                                : "No song playing"}
                        </div>
                    </div>
                    <div className="flex-item">
                        <div className="header">
                            NEXT SONG:
                        </div>
                        <div className="content">
                            {next ?
                                `${next.Artist} - ${next.Title}`
                                : "No song playing"}
                        </div>
                    </div>
                </div>
                <div className="flex-item">
                    <button onClick={playOrPause}>{playing ? "Mute" : "Play"}</button>
                </div>
            </div>
            <div className="flex-item about">
                <a href="https://radio-raw.origincode.me/">Raw</a>
                <a href="https://factoria.origincode.me/OriginCode/frontieradio">Factoria</a>
                <a href="https://github.com/OriginCode/frontieradio">GitHub</a>
            </div>
        </div>
    );
}

export default App;
