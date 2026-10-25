#!/usr/bin/env python3
"""
Arch Linux MCP Server - provides tools for interacting with Arch Linux
via pacman, paru, systemctl, and Arch Wiki.
"""
import json
import subprocess
import sys
import shutil
import urllib.request
import urllib.parse
import re
from typing import Any

# ── helpers ──────────────────────────────────────────────────────

def run(cmd: list[str], timeout: int = 15) -> str:
    """Run a command and return stdout, or error message on failure."""
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        out = r.stdout.strip()
        err = r.stderr.strip()
        if r.returncode != 0:
            return f"Error (exit {r.returncode}): {err or out or 'unknown error'}"
        return out or "(empty output)"
    except FileNotFoundError:
        return f"Error: command not found: {cmd[0]}"
    except subprocess.TimeoutExpired:
        return "Error: command timed out"
    except Exception as e:
        return f"Error: {e}"

def has_command(name: str) -> bool:
    return shutil.which(name) is not None


# ── tool implementations ─────────────────────────────────────────

def tool_search_packages(args: dict) -> str:
    """Search Arch Linux official repos for a package."""
    query = args.get("query", "")
    if not query:
        return "Error: 'query' parameter is required"
    return run(["pacman", "-Ss", query])


def tool_aur_search(args: dict) -> str:
    """Search AUR for a package (requires paru)."""
    query = args.get("query", "")
    if not query:
        return "Error: 'query' parameter is required"
    if not has_command("paru"):
        return "Error: paru is not installed (install with: sudo pacman -S paru)"
    return run(["paru", "-Ss", query])


def tool_package_info(args: dict) -> str:
    """Show detailed info about an installed package."""
    pkg = args.get("package", "")
    if not pkg:
        return "Error: 'package' parameter is required"
    return run(["pacman", "-Qi", pkg])


def tool_package_files(args: dict) -> str:
    """List files owned by an installed package."""
    pkg = args.get("package", "")
    if not pkg:
        return "Error: 'package' parameter is required"
    return run(["pacman", "-Ql", pkg])


def tool_check_updates(args: dict) -> str:
    """Check available updates from official repos."""
    return run(["pacman", "-Qu"])


def tool_aur_updates(args: dict) -> str:
    """Check available AUR updates (requires paru)."""
    if not has_command("paru"):
        return "Error: paru is not installed"
    return run(["paru", "-Qua"])


def tool_system_status(args: dict) -> str:
    """Show systemd status of a service, or list failed units."""
    service = args.get("service", "")
    if service:
        return run(["systemctl", "status", service, "--no-pager", "-l"])
    # List failed units
    return run(["systemctl", "--failed", "--no-pager"])


def tool_systemctl(args: dict) -> str:
    """Run a systemctl command (status/start/stop/restart/enable/disable)."""
    action = args.get("action", "")
    unit = args.get("unit", "")
    if not action or not unit:
        return "Error: 'action' and 'unit' are required"
    if action not in ("status", "start", "stop", "restart", "enable", "disable"):
        return f"Error: unsupported action '{action}'"
    # Only allow `status` without extra privileges
    if action != "status":
        out = run(["systemctl", "--no-pager", action, unit])
        return out
    return run(["systemctl", "status", unit, "--no-pager", "-l"])


def tool_arch_wiki(args: dict) -> str:
    """Search the Arch Wiki and return a summary."""
    query = args.get("query", "")
    if not query:
        return "Error: 'query' parameter is required"
    try:
        url = "https://wiki.archlinux.org/api.php"
        params = {
            "action": "opensearch",
            "search": query,
            "limit": 5,
            "namespace": 0,
            "format": "json",
        }
        full_url = url + "?" + urllib.parse.urlencode(params)
        req = urllib.request.Request(full_url, headers={"User-Agent": "arch-mcp-server/1.0"})
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode())
        if len(data) >= 2 and data[1]:
            results = []
            for i, title in enumerate(data[1]):
                link = data[3][i] if len(data) > 3 and i < len(data[3]) else ""
                results.append(f"- {title}: {link}")
            return "Arch Wiki results:\n" + "\n".join(results) if results else f"No results found for '{query}'"
        return f"No results found for '{query}'"
    except Exception as e:
        return f"Error searching Arch Wiki: {e}"


def tool_disk_usage(args: dict) -> str:
    """Show disk usage information."""
    path = args.get("path", "/")
    return run(["df", "-h", path])


def tool_memory_usage(args: dict) -> str:
    """Show memory usage."""
    return run(["free", "-h"])


# ── tool registry ────────────────────────────────────────────────

TOOLS: list[dict[str, Any]] = [
    {
        "name": "search_packages",
        "description": "Search Arch Linux official repositories for a package (pacman -Ss)",
        "inputSchema": {
            "type": "object",
            "properties": {
                "query": {"type": "string", "description": "Package name or search term"}
            },
            "required": ["query"],
        },
    },
    {
        "name": "aur_search",
        "description": "Search the Arch User Repository (AUR) for a package (requires paru)",
        "inputSchema": {
            "type": "object",
            "properties": {
                "query": {"type": "string", "description": "Package name or search term"}
            },
            "required": ["query"],
        },
    },
    {
        "name": "package_info",
        "description": "Show detailed info about an installed package (pacman -Qi)",
        "inputSchema": {
            "type": "object",
            "properties": {
                "package": {"type": "string", "description": "Installed package name"}
            },
            "required": ["package"],
        },
    },
    {
        "name": "package_files",
        "description": "List files owned by an installed package (pacman -Ql)",
        "inputSchema": {
            "type": "object",
            "properties": {
                "package": {"type": "string", "description": "Installed package name"}
            },
            "required": ["package"],
        },
    },
    {
        "name": "check_updates",
        "description": "Check available package updates from official repos (pacman -Qu)",
        "inputSchema": {"type": "object", "properties": {}},
    },
    {
        "name": "aur_updates",
        "description": "Check available AUR updates (requires paru)",
        "inputSchema": {"type": "object", "properties": {}},
    },
    {
        "name": "system_status",
        "description": "Show systemd service status, or list failed services if no service given",
        "inputSchema": {
            "type": "object",
            "properties": {
                "service": {"type": "string", "description": "Service name (optional)"}
            },
        },
    },
    {
        "name": "systemctl",
        "description": "Run a systemctl action on a unit (status/start/stop/restart/enable/disable). WARNING: start/stop/restart/enable/disable require elevated privileges and will prompt for sudo.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "action": {
                    "type": "string",
                    "description": "Action to perform",
                    "enum": ["status", "start", "stop", "restart", "enable", "disable"],
                },
                "unit": {"type": "string", "description": "Systemd unit name (e.g. sshd.service)"},
            },
            "required": ["action", "unit"],
        },
    },
    {
        "name": "arch_wiki",
        "description": "Search the Arch Wiki for documentation",
        "inputSchema": {
            "type": "object",
            "properties": {
                "query": {"type": "string", "description": "Search term"}
            },
            "required": ["query"],
        },
    },
    {
        "name": "disk_usage",
        "description": "Show disk usage information (df -h)",
        "inputSchema": {
            "type": "object",
            "properties": {
                "path": {"type": "string", "description": "Mount point or path (default: /)"}
            },
        },
    },
    {
        "name": "memory_usage",
        "description": "Show system memory usage (free -h)",
        "inputSchema": {"type": "object", "properties": {}},
    },
]

HANDLERS: dict[str, Any] = {
    "search_packages": tool_search_packages,
    "aur_search": tool_aur_search,
    "package_info": tool_package_info,
    "package_files": tool_package_files,
    "check_updates": tool_check_updates,
    "aur_updates": tool_aur_updates,
    "system_status": tool_system_status,
    "systemctl": tool_systemctl,
    "arch_wiki": tool_arch_wiki,
    "disk_usage": tool_disk_usage,
    "memory_usage": tool_memory_usage,
}


# ── MCP server (JSON-RPC over stdio) ─────────────────────────────

def send_message(msg: dict) -> None:
    """Write a JSON-RPC message to stdout, framed by a newline."""
    sys.stdout.write(json.dumps(msg) + "\n")
    sys.stdout.flush()


def handle_request(msg: dict) -> None:
    method = msg.get("method", "")
    params = msg.get("params", {}) or {}
    msg_id = msg.get("id")

    if method == "initialize":
        send_message({
            "jsonrpc": "2.0",
            "id": msg_id,
            "result": {
                "protocolVersion": "2024-11-05",
                "serverInfo": {
                    "name": "arch-mcp-server",
                    "version": "1.0.0",
                },
                "capabilities": {
                    "tools": {},
                },
            },
        })
    elif method == "notifications/initialized":
        pass  # No response expected
    elif method == "tools/list":
        send_message({
            "jsonrpc": "2.0",
            "id": msg_id,
            "result": {"tools": TOOLS},
        })
    elif method == "tools/call":
        name = params.get("name", "")
        arguments = params.get("arguments", {})
        handler = HANDLERS.get(name)
        if handler is None:
            send_message({
                "jsonrpc": "2.0",
                "id": msg_id,
                "error": {"code": -32601, "message": f"Tool not found: {name}"},
            })
            return
        try:
            result = handler(arguments)
            send_message({
                "jsonrpc": "2.0",
                "id": msg_id,
                "result": {
                    "content": [{"type": "text", "text": result}],
                },
            })
        except Exception as e:
            send_message({
                "jsonrpc": "2.0",
                "id": msg_id,
                "error": {"code": -32603, "message": str(e)},
            })
    else:
        send_message({
            "jsonrpc": "2.0",
            "id": msg_id,
            "error": {"code": -32601, "message": f"Method not found: {method}"},
        })


def main() -> None:
    """Main loop: read JSON-RPC messages from stdin, process them."""
    # Suppress stderr to avoid interfering with the JSON-RPC stream
    import os
    # Send an informative message on stderr so users know it's running
    print("arch-mcp-server started (reading JSON-RPC from stdin)", file=sys.stderr, flush=True)

    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            msg = json.loads(line)
        except json.JSONDecodeError as e:
            # Can't respond without an id, just ignore
            continue
        try:
            handle_request(msg)
        except Exception as e:
            send_message({
                "jsonrpc": "2.0",
                "id": msg.get("id"),
                "error": {"code": -32603, "message": f"Internal error: {e}"},
            })


if __name__ == "__main__":
    main()