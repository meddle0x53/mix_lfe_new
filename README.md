# mix lfe.new

A mix task for creating and setting up new LFE projects.

It is used to create Mix projects, capable of compiling LFE source files and
running tests written for them.
In other words Mix projects created with [mix_lfe](https://github.com/meddle0x53/mix_lfe).

## Installation

Install it with:

```
mix archive.install https://github.com/meddle0x53/mix_lfe_new/releases/download/v0.1.0/mix_lfe_new-0.2.0.ez
```

## Usage

A LFE project can be created with:

```
mix lfe.new <project_name>
```

or with:

```
mix lfe.new <project_name> --setup
```

if it should be set up.

Setting up a LFE project means downloading LFE and compiling it.
It can be done on later stage in the root of the LFE project with:

```
mix lfe.setup
```
