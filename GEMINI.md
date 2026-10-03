# Auto-Deploy Workflow
Whenever you modify, add, or delete Swift code or assets in this project, you must automatically run the deployment script in the background to push the changes to the user's iOS Simulator.

Run this exact command:
`sh install_sim2.sh &`

You do not need to wait for the command to finish or check its status unless specifically asked. Just kick it off in the background and inform the user that their changes are compiling and will pop up on their simulator shortly.
