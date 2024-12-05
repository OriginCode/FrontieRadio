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

    const {lastMessage} = useWebSocket(WS_URL);
    let lastMessageData = lastMessage ? JSON.parse(lastMessage.data) : null;

    return (
        <div className="App">
            <div className="flex-item">
                <div className="header">
                    <strong>CURRENT PLAYING:&nbsp;</strong>
                </div>
                <div className="content">
                    {lastMessageData ? lastMessageData.current.Artist + " - " + lastMessageData.current.Title : "No song playing"}
                </div>
            </div>
            <div className="flex-item">
                <div className="header">
                    <strong>NEXT SONG:&nbsp;</strong>
                </div>
                <div className="content">
                    {lastMessageData ?
                        (Object.keys(lastMessageData.next).length !== 0 ?
                            lastMessageData.next.Artist + " - " + lastMessageData.next.Title
                            : "No next song")
                        : "No next song"}
                </div>
            </div>
            <div className="flex-item">
                <button onClick={playOrPause}>{playing ? "Pause" : "Play"}</button>
            </div>
        </div>
    );
}

export default App;
