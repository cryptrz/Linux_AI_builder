This script automates the installation (tested on Ubuntu 24.04.4), set up and execution of the following: 
- NVIDIA drivers
- Docker
- Ollama
- OpenWeb UI

The objectif is to run your favorite LLMs locally and interact with them in a web browser. 

By default, I chose to run llama3.2 by default. If you prefer another one, you can go to section 5 in the script: 

`ollama pull llama3.2`

You can replace `llama3.2` with another available model. You can list them with this command:

`curl -s https://ollama.com/library | grep -oP '(?<=href="/library/)[^"]+' | sort -u`.

Or you can go directly to this page: 

https://ollama.com/library
