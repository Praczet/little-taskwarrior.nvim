# little-taskwarrior.nvim

A little helper for displaying TaskWarrior's tasks.

## Table of Contents

<!-- mtoc-start -->

* [Features](#features)
* [Screens](#screens)
  * [Tasks list without project file](#tasks-list-without-project-file)
  * [Tasks list with a project file](#tasks-list-with-a-project-file)
  * [Task list with my plugin next-birthday](#task-list-with-my-plugin-next-birthday)
* [Installation](#installation)
* [Dependency](#dependency)
* [Configuration](#configuration)
  * [Dashboard](#dashboard)
    * [Limit and Non_Project_Limit](#limit-and-non_project_limit)
  * [Project file or not](#project-file-or-not)
  * [project_replacements and shorten_sections](#project_replacements-and-shorten_sections)
    * [`project_replacements` example](#project_replacements-example)
    * ['shorten_sections' example](#shorten_sections-example)
  * [`urgency_threshold` and `highlight_groups`](#urgency_threshold-and-highlight_groups)
* [Usage](#usage)
  * [Integration with Dashboard-nvim](#integration-with-dashboard-nvim)
    * [Static](#static)
    * [Dynamic](#dynamic)
      * [Workaround - a kind of solution](#workaround---a-kind-of-solution)
* [TODO](#todo)

<!-- mtoc-end -->

## Features

For now this plugin offers the following features:

- List of task as list of string to use in the Dashboard
- For current project and others
- Just a few most urgent tasks

## Screens

### Tasks list without project file

![Tasks list without project file](assets/scr-all.png)

### Tasks list with a project file

![Tasks list with project file](assets/scr-project.png)

### Task list with my plugin next-birthday

![Task list with my plugin NextBirthday](assets/scr-bd.png)

## Installation

You can install `little-taskwarrior.nvim` using your favorite package manager.
For example with `Lazy`:

```lua
 {
  "praczet/little-taskwarrior.nvim",
  config = function()
    require("little-taskwarrior").setup({ })
  end,
}
```

## Dependency

- **[TaskWarrior](https://taskwarrior.org/)** - it uses standard export command form it
- **[Dashboard-nvim](https://github.com/nvimdev/dashboard-nvim)** - if you want to use it in a dashboard

## Configuration

```lua
--- Default configuration
M.config = {
 --- configuration for the Dashboard
 dashboard = {
  --- task limit
  limit = 5,
  --- max number of columns
  max_width = 50,
  --- if > 0 then  additional task (besides current project ones) will be added
  non_project_limit = 5,
  --- List of columns to be displayed
  columns = {
   "id",
   "project",
   "description",
   "due",
   "urgency",
  },
  --- List of replacements when getting lines for dashboard
  project_replacements = {
   ["work."] = "w.",
   ["personal."] = "p.",
  },
  --- Section separator
  sec_sep = ".",
  --- Enable or disable section shortening
  shorten_sections = true,
 },
 --- function to reload dashboard config
 get_dashboard_config = nil,
 --- toggle the logging
 debug = true,
 --- where information about taskwarrior project can be found
 project_info = ".little-taskwarrior.json",
 --- above urgency_threshold all task could be highlighted in
 --- the different way
 urgency_threshold = 9,
 --- Highlights
 highlight_groups ={
    --- for the urgent tasks (above the threshold)
    urgent = nil,
    --- default style (highlight_groups) for tasks
    not_urgnet =nil
  }
}
```

So for example to make the area of task list wider you can do:

```lua
{
  "praczet/little-taskwarrior.nvim",
  config = function()
    require("little-taskwarrior").setup({
      dashboard = {
        max_width = 80
      }
    })
  end,
}
```

### Dashboard

This section sets how the dashboard's part will be displayed.

#### Limit and Non_Project_Limit

Those two options are used to display how many tasks will be displayed. Why two?
It is connected to the `project_info` option and `.little-taskwarrior.json`
file.

If in the current folder there is no `.little-taskwarrior.json` file only
`limit` will be taken. If the `.little-taskwarrior.json` is present the `limit`
will be applied to the number of tasks in for that project and
`non_project_limit` will be used for all others tasks.

### Project file or not

If in the folder (project folder or current folder) file named
`.little-taskwarrior.json` exists. This plugin will try to read project name:

For example:

```json
{
  "project": "eos"
}
```

If it succeeds it will use it as project name therefore the display mode will be
switched to project specific mode. Which means the first task will be taken for
that specific project. And then (if configuration allows) other tasks will be
loaded. You can see this in [Tasks list with a project file](###Tasks list with a project file)

### project_replacements and shorten_sections

Those two options are use to format project names and they can be used together.

- `project_replacements` - list of replacements for project names
- `shorten_sections` - switches shortening of sections

#### `project_replacements` example

(because I like examples)

Let's assume that we have projects related to `work` and several projects
related to `personal`.
In the `personal` project we have projects like:

- `personal.dashboard-nvim`
- `personal.little-taskwarrior`

So task could look like this:

```bash
task add "I need to do something" project:personal.dashboard-nvim
```

But instead of displaying `personal.dashboard-nvim` we want to display
`p.dashboard-nvim`

Then we can add replacements in the configuration:

```lua
 project_replacements = {
   ["work."] = "w.",
   ["personal."] = "p.",
  },
```

> [!note]
> Replacements can by as regular expression

#### 'shorten_sections' example

So let's say that your projects hierarchy is much more complex (multi-levels):

- personal.develop.ltw
- personal.develop.nbd
- personal.todos
- personal.health.wo
- personal.health.doc
- personal.health.admin

Of course you can `project_replacements` to make it more readable, but this
approach will force you to add each project (subproject) manually.
`shorten_sections` will do this job automatically. Before I will try explain how
does it work look how previous list will look like:

```txt
- personal.develop.ltw  > p.d.ltw
- personal.develop.nbd  > p.d.nbd
- personal.todos        > p.todos
- personal.health.wo    > p.h.wo
- personal.health.doc   > p.h.doc
- personal.health.admin > p.h.admin
```

So, each section but last will be shortened to the first letter, the last
section will remain unchanged.

### `urgency_threshold` and `highlight_groups`

Those two options are used to highlight urgent tasks. The `urgency_threshold`
set the threshold above which task is themed to be urgent. The task becomes
urgent when `urgency >= urgency_threshold`.

`highlight_groups` is used to set the style of the tasks. It has two keys:

- `urgent` - style of urgent tasks
- `not_urgent` - style of not urgent Tasks

By **style** I mean vim's highlight. If `highlight_groups` is n t set the
default values will be used.

- `urgent` - based on default `@keyword` highlight
- `not_urgent` - based on default `Comment` highlight

You can see how they are defined in `dashboard.lua` in function: `get_default_hl_group`

> [!note]
> For unforeseen '**bug**' in the code, you can override single entries. For example:
>
> ```lua
>  {
>    "praczet/little-taskwarrior.nvim",
>    config = function()
>      require("little-taskwarrior").setup({
>        dashboard = {
>          max_width = 80
>        }
>        highlight_groups = {
>          not_urgent = {
>             italic=false,
>          }
>        }
>      })
>    end,
>  }
> ```

This will just 'switch' off italic from default `Comment` highlight

## Usage

Of course you can use it as you want. I mean you can get the list and print it.

```vim
lua print(vim.inspect(require("little-taskwarrior").get_dashboard_tasks()))
```

### Integration with Dashboard-nvim

#### Static

> [!important]
> This method will display Tasks in the Dashboard but it will not allow to refresh
> task list after command `Task`

Based on my dashboard.lua config (I am using LazyVim)

```lua
return {
  {
    "nvimdev/dashboard-nvim",
    opts = function()
      -- Getting dashboard tasks
      local ltw = require("little-taskwarrior")
      local tasks = ltw.get_dashboard_tasks()

      local logo = [[

...:::...
..   ---   ..
.    (0 0)    .
.     \=/     .
.-----------------.
(      ©ad.art      )
'''''''''''''''''''
    ]]
      local currentDate = os.date("%Y-%m-%d")
      local padding = math.floor((10 - #currentDate) / 2)
      local centeredDate = string.rep(" ", padding) .. currentDate
      logo = logo .. "\n" .. centeredDate .. "\n"
      local header = vim.split(logo, "\n")
      if tasks ~= nil then
        for _, t in ipairs(tasks) do
          table.insert(header, t)
        end
        table.insert(header, "")
      end

      local opts = {
        theme = "doom",
        config = {
          header = header,
          -- ... There is more like center, footer etc.
        },
      }
      return opts
    end,
  },
}
```

#### Dynamic

> [!important]
> It will enable refreshing the task list after command `Task`, but it requires some
> steps

Since `dashboard-nvim` does not support refreshing header you can use
`config.get_dashboard_config`. Like this:

```lua
{
  "praczet/little-taskwarrior.nvim",
  config = function()
    require("little-taskwarrior").setup({
      get_dashboard_config = function()
        -- here function that will return options for dashboard
        -- the same as in dashboard-nvim setup.
      local ltw = require("little-taskwarrior")
      local tasks = ltw.get_dashboard_tasks()

      local logo = [[

...:::...
..   ---   ..
.    (0 0)    .
.     \=/     .
.-----------------.
(      ©ad.art      )
'''''''''''''''''''
    ]]
      local currentDate = os.date("%Y-%m-%d")
      local padding = math.floor((10 - #currentDate) / 2)
      local centeredDate = string.rep(" ", padding) .. currentDate
      logo = logo .. "\n" .. centeredDate .. "\n"
      local header = vim.split(logo, "\n")
      if tasks ~= nil then
        for _, t in ipairs(tasks) do
          table.insert(header, t)
        end
        table.insert(header, "")
      end

      local opts = {
        theme = "doom",
        config = {
          header = header,
          -- ... There is more like center, footer etc.
        },
      }
      return opts
    end,
      end
    })
  end,
}
```

This will enable refreshing after `Task` command.

Now you can change configuration of `dashboard-nvim` plugin, like this:

```lua
return {
  {
    "nvimdev/dashboard-nvim",
    opts = require('little-taskwarrior').get_dashboard_config
  }
}
```

> [!warning]
> This mostly works, but sometimes `little-taskwarrior` was taking too long to
> load and then `dashboard-nvim` loaded the default one (in my case LazyVim).

##### Workaround - a kind of solution

There are many ways to solve it. For example you can put for your `dashboard-nvim`
config the function as usual, and then the same function in
`little-taskwarrior`. I do not like this (in two places the same code). It
forces me to remember to change it in two places.

I suggest this (solution for LazyVim):

1. Add a file `fallback.lua` in `~/.config/nvim/lua/`

   ```lua
   local function fall_back()
     local next = require("next-birthday")
     local lines = next.birthdays("now")

     local ltw = require("little-taskwarrior")
     local tasks = ltw.get_dashboard_tasks()
     local logo = [[

      ...:::...
      ..   ---   ..
      .    (0 0)    .
      .     \=/     .
      .-----------------.
      (      ©ad.art      )
      '''''''''''''''''''
      ]]
      local currentDate = os.date("%Y-%m-%d")
      local padding = math.floor((10 - #currentDate) / 2)
      local centeredDate = string.rep(" ", padding) .. currentDate
      logo = logo .. "\n" .. centeredDate .. "\n"
      local header = vim.split(logo, "\n")
      if lines ~= nil then
        for _, l in ipairs(lines) do
          table.insert(header, l)
        end
      end
      table.insert(header, "")

      if tasks ~= nil then
        for _, t in ipairs(tasks) do
          table.insert(header, t)
        end
        table.insert(header, "")
      end

      local opts = {
        theme = "doom",
        hide = {
          -- this is taken care of by lualine
          -- enabling this messes up the actual laststatus setting after loading a file
          statusline = false,
      },
        config = {
          header = header,
            -- stylua: ignore
       }
     }
    return opts
    end

    return {
      fall_back = fall_back,
    }
   ```

2. In the `dashboard-nvim` config use like this:

   ```lua
    --- this file contains my own Dashboard config
    local dashboard_config = require("fallback")
    return {
      {
        "nvimdev/dashboard-nvim",
        opts = dashboard_config.fall_back,
      },
    }
   ```

3. In the `little-taskwarrior` config use like this:

   ```lua
    local dashboard_config = require("fallback")
    return {
      {
        "praczet/little-taskwarrior.nvim",
        config = function()
          require("little-taskwarrior").setup({
            get_dashboard_config = dashboard_config.fall_back,
          })
        end,
      },
    }
   ```

You can see my config files in `config` folder of my repository.

## TODO

- [x] feat: Shortening project names by separator
- [x] feat: Highlight urgent tasks
- [x] feat: Preview task
- [ ] feat: Add task from selection or for current line
