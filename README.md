# Curiosity Lab

A personal collection of experiments, proof-of-concepts, automation helpers, and small tools built while exploring how systems work.

This repository is intentionally broader than a single security or automation category. Projects may involve Windows internals, Linux, networking, Android, scripting, system administration, or other technical areas that started with a simple question: **can this be done, and how does it work?**

## Experiments

### Windows

- [`sam-modifier`](windows/sam-modifier/) — a Linux-side helper for locating an offline Windows SAM hive and reducing the repetitive mounting/navigation steps involved in authorized recovery and experimentation.

## Repository structure

```text
Curiosity-Lab/
├── windows/
│   └── sam-modifier/
│       ├── SAM_modifier
│       └── README.md
└── README.md
```

As the lab grows, experiments can be grouped by area—for example `linux/`, `android/`, `networking/`, or other categories—while each substantial experiment keeps its own README, requirements, limitations, and usage notes.

## Purpose

The projects here are primarily learning artifacts and experiments, not polished production tools. Some may automate repetitive tasks; others may demonstrate a concept, investigate system behavior, or preserve something useful discovered while experimenting.

## Responsible use

Some experiments may interact with operating-system internals, credentials, filesystems, networks, or other sensitive components. Use them only on systems you own or are explicitly authorized to test or administer, and read the experiment-specific documentation before running anything.
