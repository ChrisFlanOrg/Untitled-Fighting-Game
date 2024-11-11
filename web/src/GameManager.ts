import $ from "jquery";
import { v4 as uuid } from "uuid";
// @ts-ignore
import { init as Accelerometer } from "./accelerometer";

import { ConnectionManager } from "src/ConnectionManager";

const localStorageItemName = "accelerometer-test-player-info"

enum GameState {
  Setup = 'setup',
  Rejoin = 'rejoin',
  Loading = 'loading',
  Lobby = 'lobby',
  Play = 'play',
};

enum ServerMessageType {
	WhoAreYou = 'who-are-you',
	GameState = 'game-state',
};

enum ClientMessageType {
	WhoIAm = 'who-i-am',
	GetGameState = 'get-game-state',
	PhoneMotion= 'phone-motion',
}

export class GameManager {
	static state = GameState.Setup;

	static playerId: string | undefined;
	static playerName: string | undefined;

	static roundStartTime = 0;
	static roundEndTime = 0;
	static overlayMessage = "";

	static updateHz = 10;

	static {
		ConnectionManager.addConnectHandler(() => {
			ConnectionManager.send(ClientMessageType.GetGameState);
		})

		ConnectionManager.addDisconnectHandler(() => {
			this.rejoinOrSetup();
		})

		ConnectionManager.addMessageHandler(ServerMessageType.WhoAreYou, () => {
			ConnectionManager.send(ClientMessageType.WhoIAm, {
				player_id: this.playerId,
				player_name: this.playerName,
			});
		});

		ConnectionManager.addMessageHandler(ServerMessageType.GameState, (data: any) => {
			const { state } = data;
			if (Object.values(GameState).includes(state)) {
				this.setState(state);
			}
		});
	};

	static setState(newState: GameState) {
		const prevState = this.state;
		this.state = newState;

		$(`#${this.state}_page`).show()
		Object.values(GameState).forEach(key => {
			if (key != this.state) {
				$(`#${key}_page`).hide()
			}
		})

		if (this.state === GameState.Lobby) {
			let touching = true;
			let waitTime = Date.now();
			let samples: {x: number | null, y: number | null}[] = [];
			const numSamples = 10;

			// $(`#{this.state}_page`).on("touchstart", () => {
			// 	touching = true;
			// 	waitTime = 0;
			// });

			// $(`#{this.state}_page`).on("touchend", () => {
			// 	touching = false;
			// });

   		window.addEventListener("devicemotion", (e) => {
	   		const acc = e.acceleration;
	   		if (acc && acc.x && acc.y) {
		   		const len = Math.sqrt(acc.x*acc.x + acc.y*acc.y);
			    if ((Date.now() - waitTime) > 75) {
				    if (touching && len > 5) {
					    samples.push(acc);
					    if (samples.length >= numSamples) {
						    const avg = {
							    x: samples.reduce((total, n) => total + n.x!, 0)/numSamples,
							    y: samples.reduce((total, n) => total + n.y!, 0)/numSamples,
						    }
						    const avgLen = Math.sqrt(avg.x*avg.x + avg.y*avg.y)
						    samples = [];
					   		waitTime = Date.now();
					    	ConnectionManager.send(ClientMessageType.PhoneMotion, {
						    	acc: {
							    	x: -avg.x/avgLen,
							    	y: avg.y/avgLen,
						    	},
					    	});
					    }
				    }
			    } else {
				    if (len > 3.5) {
			   			waitTime = Date.now();
				    }
			    }
	   		}
   		})
		}
	}

	static generateNewPlayerInfo() {
		const playerInfo = {
			playerId: uuid(),
			playerName: $("#player_name").val()!.toString(),
		};

		this.playerId = playerInfo.playerId;
		this.playerName = playerInfo.playerName;

		localStorage.setItem(localStorageItemName, JSON.stringify(playerInfo));

		return playerInfo;
	}

	static loadPlayerInfo() {
		const playerInfo = (() => {
			try {
				const storageItem = localStorage.getItem(localStorageItemName);
				if (!storageItem) {
					return undefined;
				}
				const { playerId, playerName } = JSON.parse(storageItem);

				if (playerId && playerName) {
					return { playerId, playerName };
				}
			} catch {
				// Intentionally do nothing
			}

			return undefined;
		})();

		if (playerInfo) {
			this.playerId = playerInfo.playerId;
			this.playerName = playerInfo.playerName;

			localStorage.setItem(localStorageItemName, JSON.stringify(playerInfo));
		}

		return playerInfo;
	};

	static clearPlayerInfo() {
		localStorage.removeItem(localStorageItemName);
		this.playerId = undefined;
		this.playerName = undefined;
	};

	static rejoinOrSetup() {
		const playerInfo = this.loadPlayerInfo();

		if (playerInfo) {
			$("#rejoin").val(`Rejoin as ${playerInfo.playerName}`);
			this.setState(GameState.Rejoin);
		} else {
			this.setState(GameState.Setup);
		}
	}

	static getDeviceMovePermission() {
		if ( typeof( DeviceMotionEvent ) !== "undefined" && typeof( (DeviceMotionEvent as any).requestPermission ) === "function" ) {
        // (optional) Do something before API request prompt.
        (DeviceMotionEvent as any).requestPermission()
            .then((response: any) => {
            // (optional) Do something after API prompt dismissed.
            if ( response == "granted" ) {
            } else {
	            //alert(response);
            }
        })
            .catch( console.error )
    } else {
        //alert( "DeviceMotionEvent is not defined" );
    }
	}

	static setup() {
		console.log(document.getElementById("player_name_submit"))
		document.getElementById("player_name_submit")!.onclick = (e: MouseEvent) => {
			this.generateNewPlayerInfo();
			this.setState(GameState.Loading);
			this.getDeviceMovePermission();
			ConnectionManager.connect();
		};

		document.getElementById("rejoin")!.addEventListener("click", (() => {
			this.setState(GameState.Loading);
			this.getDeviceMovePermission();
			ConnectionManager.connect();
		}));

		$("#join_as_new_player").click(() => {
			this.clearPlayerInfo();
			this.setState(GameState.Setup);
		});

		setTimeout(this.loop.bind(this), 0);

		this.rejoinOrSetup();
	}

	static loop() {
		if (this.state === GameState.Play) {
			// Send accel data
		}

		setTimeout(this.loop.bind(this), 1000 / this.updateHz);
	}
}
