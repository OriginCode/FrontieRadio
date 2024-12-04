import './App.css';
import React from "react";
import useWebSocket from "react-use-websocket";

function App() {
    const WS_URL = "ws://127.0.0.1:8081/";
    const {lastMessage} = useWebSocket(WS_URL);
    let lastMessageData = lastMessage ? JSON.parse(lastMessage.data) : null;
    return (
        <div className="App">
            <table>
                <tbody>
                <tr align="left">
                    <th scope="row" align="right"><strong>CURRENT PLAYING:&nbsp;</strong></th>
                    {lastMessageData ? lastMessageData.current.Artist + " - " + lastMessageData.current.Title : "No song playing"}
                </tr>
                <tr align="left">
                    <th scope="row" align="right"><strong>NEXT SONG:&nbsp;</strong></th>
                    {lastMessageData ? lastMessageData.next.Artist + " - " + lastMessageData.next.Title : "No next song"}
                </tr>
                </tbody>
            </table>
        </div>
    );
}

export default App;
