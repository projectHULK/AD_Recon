# Tool Overview
SharpSCCM is a post-exploitation tool designed to leverage Microsoft Endpoint Configuration Manager (a.k.a. ConfigMgr, formerly SCCM) for lateral movement and credential gathering without requiring access to the SCCM administration console GUI. 

SharpSCCM was initially created to execute user hunting and lateral movement functions ported from PowerSCCM (by @harmj0y, @jaredcatkinson, @enigma0x3, and @mattifestation) and now contains additional functionality to gather credentials and abuse newly discovered attack primitives for coercing NTLM authentication in SCCM sites where automatic site-wide client push installation is enabled.

Please [visit the wiki](https://github.com/Mayyhem/SharpSCCM/wiki) for documentation detailing how to build and use SharpSCCM.

### Author
Chris Thompson is the primary author of this project. Duane Michael (@subat0mik) and Evan McBroom (@mcbroom_evan) are active contributors as well. Please feel free to reach out on Twitter (@_Mayyhem) with questions, ideas for improvements, etc., and on GitHub with issues and pull requests.

### Warning
This tool was written as a proof of concept in a lab environment and has not been thoroughly tested. There are lots of unfinished bits, terrible error handling, and functions I may never complete. Please be careful and use at your own risk.
