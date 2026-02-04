# Azure Well-Architected Framework (WAF) Snippets

![Azure WAF](https://learn.microsoft.com/en-us/azure/well-architected/media/waf-diagram.png)

This repository contains a collection of code snippets, demos, and Proof of Concepts (PoC) designed for **Azure Well-Architected Framework** presentations and meetups.

It serves as a sandbox for demonstrating best practices, automation, and architectural patterns across the five pillars of the WAF.

## 📚 WAF Pillars

The content is organized by the pillars of the Microsoft Azure Well-Architected Framework:

*   [💰 Cost Optimization](#-cost-optimization)
*   [⚡ Performance Efficiency](#-performance-efficiency)
*   [🛡️ Security](#-security)
*   [🔧 Operational Excellence](#-operational-excellence)
*   [💪 Reliability](#-reliability)

---

## 💰 Cost Optimization

Managing and visualizing cloud costs effectively starts with good governance.

### 🏷️ [Azure Auto-Tagging](./cost-optimization/azure-autotagging/)

A "Vibe-coded" Azure Function that ensures automatic tagging of all Azure Resources to enable better cost tracking and ownership accountability.

*   **Goal**: Automatically identify who created or modified a resource.
*   **Tags Applied**: `created-by`, `modified-by`.
*   **Tech Stack**: Azure Functions (.NET 8), Event Grid, Bicep.

[👉 View Documentation & Usage](./cost-optimization/azure-autotagging/README.md)

---

## 🤝 Contributing

This is a personal repository for community talks. Feel free to explore the snippets and use them in your own environments.

## 📝 License

See the [LICENSE](LICENSE) file for details.
