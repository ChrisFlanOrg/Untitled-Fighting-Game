type HandlerFn<Args extends any[] = []> = (...args: Args) => void;

export class ConnectionManager {
	static socket: WebSocket | undefined;
	static messageHandlers: {[key: string]: HandlerFn<[any]>[]} = {};

	static addMessageHandler(type: string, handlerFn: HandlerFn<[any]>) {
		if (this.messageHandlers[type] == null) {
			this.messageHandlers[type] = [];
		}

		this.messageHandlers[type].push(handlerFn);
	}

	static connectHandlers: HandlerFn[] = [];
	static addConnectHandler(handlerFn: HandlerFn) {
		this.connectHandlers.push(handlerFn);
	}

	static disconnectHandlers: HandlerFn[] = [];
	static addDisconnectHandler(handlerFn: HandlerFn) {
		this.disconnectHandlers.push(handlerFn);
	}

	static connect() {
		// Create WebSocket connection.
		this.socket = new WebSocket(`ws://${window.location.hostname}:8081`);

		this.socket.addEventListener("open", () => {
			console.log("Open!");
			this.connectHandlers.forEach(handler => {
				handler();
			});
		});

		this.socket.addEventListener("close", () => {
			this.socket = undefined;
			this.disconnectHandlers.forEach(handler => {
				handler();
			});
		});

		this.socket.addEventListener("message", event => {
			try {
				const messageData = JSON.parse(event.data);

				const handlers = this.messageHandlers[messageData.type] || [];

				handlers.forEach(handler => {
					handler(messageData.data);
				});
			} catch (e) {
				console.error(e);
			}
		});

		this.addMessageHandler("ping", () => {
			this.send('pong')
		})
	}

	static send(type: string, data?: any) {
		if (!this.socket) {
			return;
		}

		if (data != null) {
			this.socket.send(JSON.stringify({ type, data }));
		} else {
			this.socket.send(JSON.stringify({ type }));
		}
	}
}
