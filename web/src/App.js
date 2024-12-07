import './App.css';
import React, {useEffect, useState} from "react";
import useWebSocket from "react-use-websocket";

function App() {
    const AUDIO_URL = "https://radio-raw.origincode.me/";
    const WS_URL = "wss://radio-api.origincode.me/";

    const [audio] = useState(new Audio(AUDIO_URL));
    const [playing, setPlaying] = useState(false);
    const playOrPause = () => setPlaying(!playing);
    useEffect(() => {
            playing ? audio.play() : audio.pause();
        },
        [audio, playing]
    );
    useEffect(() => {
        audio.addEventListener('ended', () => setPlaying(false));
        return () => {
            audio.removeEventListener('ended', () => setPlaying(false));
        };
    }, [audio]);

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
    useEffect(() => {
        console.log(lastMessage);
    }, [lastMessage]);
    let lastMessageData = lastMessage ? JSON.parse(lastMessage.data) : null;

    return (
        <div className="App">
            <div className="main">
                <div className="info">
                    <div className="flex-item">
                        <div className="header">
                            CURRENT PLAYING:
                        </div>
                        <div className="content">
                            {lastMessageData ?
                                (Object.keys(lastMessageData.current).length !== 0 ?
                                    lastMessageData.current.Artist + " - " + lastMessageData.current.Title 
                                    : "No song playing")
                                : "No song playing"}
                        </div>
                    </div>
                    <div className="flex-item">
                        <div className="header">
                            NEXT SONG:
                        </div>
                        <div className="content">
                            {lastMessageData ?
                                (Object.keys(lastMessageData.next).length !== 0 ?
                                    lastMessageData.next.Artist + " - " + lastMessageData.next.Title
                                    : "No next song")
                                : "No next song"}
                        </div>
                    </div>
                </div>
                <div className="flex-item">
                    <button onClick={playOrPause}>{playing ? "Pause" : "Play"}</button>
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
