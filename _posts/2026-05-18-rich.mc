---
title: "Rich: I wanted to make my Terminal app Useful"
date: 2026-05-18 09:00:00 +0000
categories: [Python, Dev Tools]
tags: [python, Rich, terminal]
description: "Rich: I wanted to create terminal apps that were easy and intuitive for my users. Rich was the solution."
---

# Rich: I wanted to make my Terminal app Useful

If you've ever stared at a wall of plain text in your terminal and thought *"there has to be a better way"* — there is. It's called **Rich**, and it will change how you think about command-line output forever.

---

## Who Built It?

Rich was created by **Will McGugan**, a British software developer, and first released in 2020. McGugan built it out of frustration with the limitations of standard terminal output. He wanted a library that felt as expressive as HTML/CSS but worked entirely in the terminal.

The project took off quickly. Today it has over **47,000 stars on GitHub**, is downloaded millions of times per month, and is used by major projects like FastAPI, Textual, Pytest, and AWS CLI.

McGugan later used Rich as the foundation for **Textual** — a full TUI (Terminal User Interface) framework — which is essentially Rich's spiritual successor for building complete terminal applications.

---

## What Can Rich Do?

Rich turns your terminal into a canvas. Here's what it brings to the table:

### Styled Text
Apply colors, bold, italic, underline, strikethrough — all using simple markup tags that feel like HTML.

```python
from rich import print

print("[bold magenta]Hello[/bold magenta], [green]world![/green]")
print("[red underline]Warning:[/red underline] Something went wrong.")
print("[on blue] Inverted background [/on blue]")
```

It supports **256 colors**, **True Color (16 million colors via RGB)**, and automatically degrades gracefully on terminals that support fewer colors.

---

### Tables
One of Rich's most powerful features. You define columns, add rows, and Rich handles all the alignment, borders, and formatting.

```python
from rich.console import Console
from rich.table import Table

console = Console()

table = Table(title="Top Programming Languages 2024")
table.add_column("Language", style="cyan", no_wrap=True)
table.add_column("Created By", style="magenta")
table.add_column("Year", justify="right", style="green")
table.add_column("Primary Use", style="yellow")

table.add_row("Python", "Guido van Rossum", "1991", "General purpose / Data / AI")
table.add_row("Rust", "Graydon Hoare", "2010", "Systems programming")
table.add_row("TypeScript", "Anders Hejlsberg", "2012", "Web development")
table.add_row("Go", "Google", "2009", "Cloud / Backend")

console.print(table)
```

Tables support column alignment, custom styles per column, custom border styles, and even nested content.

---

### Progress Bars
Track long-running tasks with animated progress bars — either simple one-liners or complex multi-task views.

```python
from rich.progress import track
import time

# The easy way — wrap any iterable
for item in track(my_list, description="Processing..."):
    process(item)

# The powerful way — multiple concurrent tasks
from rich.progress import Progress

with Progress() as progress:
    task1 = progress.add_task("[cyan]Downloading...", total=1000)
    task2 = progress.add_task("[magenta]Processing...", total=500)

    while not progress.finished:
        progress.update(task1, advance=10)
        progress.update(task2, advance=5)
        time.sleep(0.02)
```

---

### Panels and Layout
Wrap content in bordered panels, display things in columns, or build full split-screen layouts.

```python
from rich.panel import Panel
from rich.columns import Columns
from rich.console import Console

console = Console()

# A simple panel
console.print(Panel("This is inside a panel", title="Info", border_style="blue"))

# Side-by-side columns
panels = [Panel(f"Item {i}", expand=True) for i in range(1, 4)]
console.print(Columns(panels))
```

---

### Syntax Highlighting
Display code with full syntax highlighting for dozens of languages — useful for developer tools and REPLs.

```python
from rich.syntax import Syntax
from rich.console import Console

console = Console()
code = '''
def greet(name: str) -> str:
    return f"Hello, {name}!"
'''
syntax = Syntax(code, "python", theme="monokai", line_numbers=True)
console.print(syntax)
```

---

### Logging Integration
Drop-in replacement for Python's standard logging — adds timestamps, log levels in color, and source file context with a single line.

```python
import logging
from rich.logging import RichHandler

logging.basicConfig(
    level=logging.DEBUG,
    format="%(message)s",
    handlers=[RichHandler()]
)

log = logging.getLogger("myapp")
log.info("Server started on port 8080")
log.warning("Memory usage at 85%")
log.error("Database connection failed")
```

---

### `inspect()` — Object Explorer
A visual alternative to Python's `help()`. Prints a clean, color-coded summary of any object's attributes and methods.

```python
from rich import inspect

inspect([])            # Inspect a list
inspect(str)           # Inspect a class
inspect(os, methods=True)  # Inspect a module with all methods
```

---

## Building an Interactive Table App

Here's a complete, runnable app that displays a movie database in a table and lets the user filter, sort, and explore it interactively.

The app uses:
- **Rich** for all visual output
- Python's built-in `input()` for interaction
- No external dependencies beyond Rich

```python
# movie_explorer.py
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.prompt import Prompt, Confirm
from rich.text import Text
from rich import box

console = Console()

# --- Data ---
MOVIES = [
    {"title": "Inception",        "year": 2010, "genre": "Sci-Fi",   "director": "Christopher Nolan", "rating": 8.8},
    {"title": "The Godfather",    "year": 1972, "genre": "Crime",    "director": "Francis Ford Coppola", "rating": 9.2},
    {"title": "Interstellar",     "year": 2014, "genre": "Sci-Fi",   "director": "Christopher Nolan", "rating": 8.6},
    {"title": "Parasite",         "year": 2019, "genre": "Thriller", "director": "Bong Joon-ho",      "rating": 8.5},
    {"title": "The Dark Knight",  "year": 2008, "genre": "Action",   "director": "Christopher Nolan", "rating": 9.0},
    {"title": "Pulp Fiction",     "year": 1994, "genre": "Crime",    "director": "Quentin Tarantino", "rating": 8.9},
    {"title": "Dune",             "year": 2021, "genre": "Sci-Fi",   "director": "Denis Villeneuve",  "rating": 8.0},
    {"title": "Whiplash",         "year": 2014, "genre": "Drama",    "director": "Damien Chazelle",   "rating": 8.5},
    {"title": "Get Out",          "year": 2017, "genre": "Horror",   "director": "Jordan Peele",      "rating": 7.7},
    {"title": "Everything Everywhere All at Once", "year": 2022, "genre": "Sci-Fi", "director": "Daniels", "rating": 7.8},
]

GENRE_COLORS = {
    "Sci-Fi":   "cyan",
    "Crime":    "red",
    "Thriller": "magenta",
    "Action":   "yellow",
    "Drama":    "blue",
    "Horror":   "dark_red",
}


def rating_bar(rating: float) -> Text:
    """Turn a numeric rating into a colored visual bar."""
    filled = int(rating)
    bar = "█" * filled + "░" * (10 - filled)
    color = "green" if rating >= 8.5 else "yellow" if rating >= 7.5 else "red"
    return Text(f"{bar} {rating}", style=color)


def build_table(movies: list, title: str = "Movie Explorer") -> Table:
    """Build and return a Rich Table from a list of movie dicts."""
    table = Table(
        title=title,
        box=box.ROUNDED,
        border_style="bright_black",
        header_style="bold white on dark_blue",
        show_lines=True,
    )

    table.add_column("#",         style="dim",     width=4,  justify="right")
    table.add_column("Title",     style="bold",    min_width=20)
    table.add_column("Year",      justify="center", width=6)
    table.add_column("Genre",     width=10)
    table.add_column("Director",  style="italic",  min_width=18)
    table.add_column("Rating",    min_width=18)

    for i, movie in enumerate(movies, 1):
        genre = movie["genre"]
        genre_color = GENRE_COLORS.get(genre, "white")
        genre_text = Text(genre, style=f"bold {genre_color}")

        table.add_row(
            str(i),
            movie["title"],
            str(movie["year"]),
            genre_text,
            movie["director"],
            rating_bar(movie["rating"]),
        )

    return table


def show_menu() -> None:
    """Print the main menu."""
    console.print(Panel(
        "[1] Browse all movies\n"
        "[2] Filter by genre\n"
        "[3] Filter by director\n"
        "[4] Sort by rating\n"
        "[5] Sort by year\n"
        "[6] Search by title\n"
        "[q] Quit",
        title="[bold cyan]Main Menu[/bold cyan]",
        border_style="cyan",
        expand=False,
    ))


def filter_by_genre(movies: list) -> list:
    genres = sorted(set(m["genre"] for m in movies))
    console.print("\nAvailable genres: " + ", ".join(f"[bold]{g}[/bold]" for g in genres))
    choice = Prompt.ask("Enter genre")
    return [m for m in movies if m["genre"].lower() == choice.lower()]


def filter_by_director(movies: list) -> list:
    choice = Prompt.ask("Enter director name (partial match ok)")
    return [m for m in movies if choice.lower() in m["director"].lower()]


def search_by_title(movies: list) -> list:
    query = Prompt.ask("Enter title to search")
    return [m for m in movies if query.lower() in m["title"].lower()]


def main() -> None:
    console.clear()
    console.print(Panel(
        "[bold white]Welcome to[/bold white] [bold magenta]Movie Explorer[/bold magenta]\n"
        "[dim]Powered by Rich[/dim]",
        border_style="magenta",
        expand=False,
    ))

    movies = MOVIES.copy()

    while True:
        console.print()
        show_menu()
        console.print()

        choice = Prompt.ask("[bold]Your choice[/bold]", choices=["1","2","3","4","5","6","q"])

        console.print()

        if choice == "q":
            console.print("[bold green]Goodbye! 🎬[/bold green]")
            break

        elif choice == "1":
            table = build_table(movies, f"All Movies ({len(movies)} total)")
            console.print(table)

        elif choice == "2":
            filtered = filter_by_genre(movies)
            if filtered:
                console.print(build_table(filtered, f"Genre Filter — {len(filtered)} results"))
            else:
                console.print("[red]No movies found for that genre.[/red]")

        elif choice == "3":
            filtered = filter_by_director(movies)
            if filtered:
                console.print(build_table(filtered, f"Director Filter — {len(filtered)} results"))
            else:
                console.print("[red]No movies found for that director.[/red]")

        elif choice == "4":
            sorted_movies = sorted(movies, key=lambda m: m["rating"], reverse=True)
            console.print(build_table(sorted_movies, "Sorted by Rating (highest first)"))

        elif choice == "5":
            sorted_movies = sorted(movies, key=lambda m: m["year"], reverse=True)
            console.print(build_table(sorted_movies, "Sorted by Year (newest first)"))

        elif choice == "6":
            results = search_by_title(movies)
            if results:
                console.print(build_table(results, f"Search Results — {len(results)} found"))
            else:
                console.print("[red]No movies matched your search.[/red]")

        console.print()
        if not Confirm.ask("Back to menu?", default=True):
            console.print("[bold green]Goodbye! 🎬[/bold green]")
            break


if __name__ == "__main__":
    main()
```

### Running the App

```bash
pip install rich
python movie_explorer.py
```

---

## Key Concepts from the App

| Concept | What it does |
|---|---|
| `Console()` | The central object — controls output, width, color support |
| `Table` | Defines structure; each column gets its own style and alignment |
| `Text` | A styled string you can build programmatically and embed anywhere |
| `Prompt.ask()` | Asks the user for input, with optional validation and choices |
| `Confirm.ask()` | Asks a yes/no question |
| `Panel` | Wraps any content in a border with an optional title |
| `box.ROUNDED` | One of many border styles — others include `SIMPLE`, `HEAVY`, `DOUBLE` |
| `console.clear()` | Clears the terminal, useful for refreshing the view |

---

## Tips and Tricks

**Export to HTML or SVG** — Rich can save its output as a static file:
```python
console = Console(record=True)
console.print(table)
console.save_html("output.html")
console.save_svg("output.svg")
```

**Disable color for CI/logs** — Rich detects whether it's running in a terminal automatically. You can also force it:
```python
console = Console(no_color=True)   # Plain text
console = Console(force_terminal=True)  # Always colored
```

**Markdown rendering** — Rich can render Markdown directly in the terminal:
```python
from rich.markdown import Markdown
console.print(Markdown("# Hello\n\nThis is **bold** and this is `code`."))
```

---

## Final Thoughts

Rich is one of those rare libraries that improves your workflow the moment you install it. Whether you're building dev tools, data pipelines, CLI apps, or just want better debug output, Rich makes the terminal feel like a first-class environment — not an afterthought.

The interactive table app above is just a starting point. From here you could add pagination, export options, live-updating views with `Live`, or even migrate to **Textual** when you need mouse support and full TUI widgets.

> **GitHub:** [github.com/Textualize/rich](https://github.com/Textualize/rich)  
> **Docs:** [rich.readthedocs.io](https://rich.readthedocs.io)
