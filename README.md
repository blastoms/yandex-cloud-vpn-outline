# Quick VPN with Yandex Cloud

## What is it?

There are days, when you need to access a web-site hosted in Russia, which has prevented the out-of-the-country access.
Unfortunately, some utility providers do this, yet you still need to pay for the utilities when you have fled
the country.

Yandex.Cloud allows you to create a low-cost preemptive virtual machine for under a rouble per hour. Instruction and the
script in this repo help you create such a virtual machine.

## How to prepare?

1. Set up Yandex Cloud account.
2. Configure the [billing account in Yandex Cloud](https://console.cloud.yandex.ru/billing/create-account).
3. Install [yc](https://cloud.yandex.com/en/docs/cli/quickstart).
4. Restart your shell to make `yc` command available.
5. Configure `yc` by calling `yc init`.
6. [Install Outline Manager and Outline Client](https://getoutline.org/get-started/) on the device where you want to use VPN.
7. Ensure you have an SSH-key generated, with public key saved as `~/.ssh/id_rsa.pub`.
8. Download [do.sh](./do.sh) and run it, following the on-screen instructions. Keep the script running for now.
9. Open Outline Manager, choose *"Set up Outline anywhere"* and copy the config displayed by the script (including curly brackets) into Step 2.
10. Copy created "Access key" of the server from Outline Manager.
11. Open Outline Client, add server, paste copied "Access key" and connect to VPN.
12. When you're finished, press "Enter" in the terminal where you have the script running. It should remove the created virtual machine. Check that the server was removed from [Yandex Cloud](https://console.cloud.yandex.ru/).

Below is the example produced by this script (so you'll know what to look for in the output):
```json
{"apiUrl":"https://51.250.74.81:61648/ui2mtnfFtm-awV8pbIcVQQ","certSha256":"FA3A90DD2C1ADCF13B724872C784C44DC71D28B7A3A927A52172F774363A6F71"}
```

Example of "Access key" of the server from Outline Manager:
```text
ss://Y2hhY2hhMjAtaWV0Zi1wb2x5MTMwNTpsQVY3S00wSTB1bWdCZG16ZmxXNG5G@51.250.74.81:45142/?outline=1
```