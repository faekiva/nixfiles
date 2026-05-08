import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.unregisterProvider("amazon-bedrock");
  pi.unregisterProvider("anthropic");
  pi.unregisterProvider("openrouter");
}
