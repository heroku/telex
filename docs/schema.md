```


          ████████╗███████╗██╗     ███████╗██╗  ██╗
          ╚══██╔══╝██╔════╝██║     ██╔════╝╚██╗██╔╝
             ██║   █████╗  ██║     █████╗   ╚███╔╝
             ██║   ██╔══╝  ██║     ██╔══╝   ██╔██╗
             ██║   ███████╗███████╗███████╗██╔╝ ██╗
             ╚═╝   ╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝

     ███████╗ ██████╗██╗  ██╗███████╗███╗   ███╗ █████╗
     ██╔════╝██╔════╝██║  ██║██╔════╝████╗ ████║██╔══██╗
     ███████╗██║     ███████║█████╗  ██╔████╔██║███████║
     ╚════██║██║     ██╔══██║██╔══╝  ██║╚██╔╝██║██╔══██║
     ███████║╚██████╗██║  ██║███████╗██║ ╚═╝ ██║██║  ██║
     ╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝


  ┌───────────────────────┐              ┌───────────┐
  │                       │              │           │
  │       producers       │              │   users   │
  │                       │              │           │
  └───────────────────────┘              └───────────┘
              ▲                                ▲
              ┃                                ┃
              ┃                                ┃
              ┃                                ┃
              ┃                                ┃
              ┃                                ┃
     ┌─────────────────┐            ┌────────────────────┐
     │                 │            │                    │
     │    messages     │◀━━━━━━━━━━━│   notifications    │
     │                 │            │                    │
     └─────────────────┘            └────────────────────┘
              ▲
              ┃
              ┃              Legend══════════════════════╗
              ┃              ║                           ║
              ┃              ║        A ━━━━━━▶ B        ║
       ┌─────────────┐       ║                           ║
       │             │       ║       B has many A        ║
       │  followups  │       ║                           ║
       │             │       ║     A has foreign key     ║
       └─────────────┘       ║      constraint on B      ║
                             ║                           ║
                             ╚═══════════════════════════╝
```
