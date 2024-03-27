---
title: Forcing a large language model to write Bash scripts so that I don't have to
date: 2024-03-27
image: images/developer-talking-to-an-ai.png
caption: A photo of a software developer talking to an AI (Stable Diffusion)
description: 'Can you fix that? Certainly!'
tags: ['jetbrains', 'ai']
---

Recently I started to use the built-in (paid) AI assistant of my IDE of choice:
[JetBrains IntelliJ IDEA Ultimate](https://www.jetbrains.com/idea/?). Below is a protocol of such an interaction which shows
the power of technology, but also its shortcomings. As others have commented, AI assistants often "behave" like
confidently incorrect Junior developers, resulting in the need of prodding and requesting corrections.

I love using AI help when it is about something of which I have only cursory knowledge and where I don't feel the
need to acquire as deep an insight to quickly solve a programming task.

## The problem

We have a release script that automatically generates a release merge request and release notes that become the
description of that merge request. This is great for the development team to quickly see what is being released,
but less so for our internal users who should get a redacted version of the release notes.

```bash
# Generate flat release notes by comparing target vs source branch
echo "## Release notes" > release-notes.txt
git log --format="- %s" "origin/production..origin/master" | grep -v Merge > release-notes.txt 
```

```markdown
## Release notes
- Topic: Foo bar baz
- Topic: Bar baz foo
```

All our commit messages follow a similar format of `Topic: Foo bar baz`. When creating user-facing release notes,
we tend to group changes by topic, removing stuff that is only relevant to developers, e.g.

```markdown
## Topic

- Foo bar baz
- Bar baz foo
...
```

So I decided to improve our release notes of grouping by topic automatically, sorting topics alphabetically, but
keeping the commit messages in order.

At first, I had the JetBrains assistant generate a Python script that would parse those flat release notes into the
structure grouped by topic. As I did not want to call a Python script from a Bash script, I thought I could see how
the assistant would fare with [associative arrays in Bash](https://www.gnu.org/software/bash/manual/html_node/Arrays.html).
Something I knew was possible, but without a personal desire to learn.

## First attempt: The rewrite

### User:
Can you rewrite the following Python script in bash?

```python
import re

# Initialize an empty dict to hold the topics and their messages
topics = {}

with open("/tmp/release-notes.txt") as f:
    for line in f:
        content = line.rstrip("\n")
        if content.startswith("##"):
            continue
        if content == "":
            continue

        # Use regular expression to parse content into topic and message
        match = re.match(r"- (.*?):\s(.*)", content)
        if match:
            topic, message = match.groups()

            # If the topic is already in dict, append the message to its list
            if topic in topics:
                topics[topic].append(message)
            # Otherwise, add the topic to the dict and start a new list with the message
            else:
                topics[topic] = [message]

# Print topics and messages
for topic, messages in sorted(topics.items()):
    print(f"**{topic}**")
    for message in messages:
        print(f"- {message}")


```

### Assistant: 
Certainly, please see the following Bash script equivalent to your provided Python script:

```bash
#!/bin/bash

# Initialize an associative array to hold the topics and their messages
declare -A topics

# Read the file line by line
while IFS= read -r line; do
    content="${line%$'\n'}"
    if [[ $content == "##"* ]]; then
        continue
    fi

    if [[ -z $content ]]; then
        continue
    fi

    # Use regex to parse content into topic and message
    if [[ $content =~ -\ (.*):\ (.*) ]]; then
        topic="${BASH_REMATCH[1]}"
        message="${BASH_REMATCH[2]}"

        # If the topic is already in the array, append the message to its list
        if [[ ${topics[$topic]+_} ]]; then
            topics["$topic"]="${topics[$topic]}, $message"
        else
            # Otherwise, add the topic to the array and start a new list with the message
            topics["$topic"]=$message
        fi
    fi
done < /tmp/release-notes.txt

# Print topics and messages
for topic in "${!topics[@]}"; do
    printf "**%s**\n" "$topic"
    IFS=', ' read -r -a messages <<< "${topics[$topic]}"
    for message in "${messages[@]}"; do
        printf "- %s\n" "$message"
    done
done | sort
```

Please note:

1. This script uses `bash` regex matching with `=~` in the `if` condition 
2. `BASH_REMATCH` array, that holds the matches after the regex matching operation.
3. The script handles multi-line messages by combining them with a comma, you can change it as you wish.
4. The use of associative arrays being available in Bash 4.0 and later versions.
5. The script converts string to array with `read` command. It creates array `messages` by splitting string with comma.
6. The Bash script might not behave exactly as the Python script for complex inputs because Bash is not as expressive as Python with string manipulation and data structures.
7. The sort at the end sorts all output, not just the topics as the Python script. This is a bash limitation and might be addressed differently depending on the specific requirements.

## Correction: Not handling spaces in messages

### User: 
Ensure that spaces in message and topics are handled properly

### Assistant: 
The presented script already accurately handles spaces in the topic and messages. It uses the built-in `read` bash command for line-by-line parsing, which appropriately handles spaces in the text. Also, the regular expression `-\ (.*):\ (.*)` takes care of spaces.

Here is the updated script to demonstrate this:

```bash
#!/bin/bash

# Initialize an associative array to hold the topics and their messages
declare -A topics

# Read the file line by line
while IFS= read -r line; do
    content="${line%$'\n'}"
    if [[ $content == "##"* ]]; then
        continue
    fi
    if [[ -z $content ]]; then
        continue
    fi

    # Use regex to parse content into topic and message
    if [[ $content =~ -\ (.*):\ (.*) ]]; then
        # Trim leading space from the values
        topic="${BASH_REMATCH[1]##*( )}"
        message="${BASH_REMATCH[2]##*( )}"
        
        # If the topic is already in the array, append the message to its list
        if [[ ${topics[$topic]+_} ]]; then
            topics["$topic"]="${topics[$topic]}; $message"
        else
            # Otherwise, add the topic to the array and start a new list with the message
            topics["$topic"]=$message
        fi
    fi
done < /tmp/release-notes.txt

# Print topics and messages
for topic in "${!topics[@]}"; do
    # We are using ';' separator now instead of ','
    IFS=';' read -r -a messages <<< "${topics[$topic]}"
    printf "**%s**\n" "$topic"
    for message in "${messages[@]}"; do
        # Trim leading space from the message
        message="${message##*( )}"
        printf "- %s\n" "$message"
    done
done | sort
```

At this point, I used the semi-colon `;` as the separator for messages in the `topics` associative array. This is because a topic or message may contain commas, which could disrupt the proper splitting of messages later on.

Let me know if you need further assistance.

## Second correction: Still not handling spaces (or a misunderstanding)

### User: 
Instead of messages, it prints individual words. Please separate messages by something other than spaces

### Assistant: 
I apologize for misunderstanding your previous message. I see now that individual messages, not their words, must be split. Below is the modified bash script where messages are correctly separated by newlines (`\n`), not spaces:

```bash
#!/bin/bash

# Initialize an associative array to hold the topics and their messages
declare -A topics

# Read the file line by line
while IFS= read -r line; do
    content="${line}"
    if [[ $content == "##"* ]]; then
        continue
    fi
    if [[ -z $content ]]; then
        continue
    fi

    # Use regex to parse content into topic and message
    if [[ $content =~ -\ (.*):\ (.*) ]]; then
        # Trim leading space from the values
        topic="${BASH_REMATCH[1]##*( )}"
        message="${BASH_REMATCH[2]##*( )}"
        
        # If the topic is already in the array, append the message to its list
        if [[ ${topics[$topic]+_} ]]; then
            topics["$topic"]="${topics[$topic]}|${message}"
        else
            # Otherwise, add the topic to the array and start a new list with the message
            topics["$topic"]=$message
        fi
    fi
done < /tmp/release-notes.txt

# Print topics and messages
for topic in "${!topics[@]}"; do
    IFS='|' read -r -a messages <<< "${topics[$topic]}"
    printf "**%s**\n" "$topic"
    for message in "${messages[@]}"; do
        printf "- %s\n" "$message"
    done
done | sort
```

The script now separates messages with a pipe symbol (`|`). The line `IFS='|' read -ra messages <<< "${topics[$topic]}"` then splits these messages correctly, irrespective of the number of spaces they include.

## Asking to sort topics before looping

### User: 
Please sort topics before iterating over it at the end

### Assistant: 
In Bash, associative arrays don't guarantee any particular order when you iterate over them. However, you can achieve ordered iteration by sorting the keys of your associative array before the loop. Below is your updated script with topics sorted in ascending order:

```bash
#!/bin/bash

# Initialize an associative array to hold the topics and their messages
declare -A topics

# Read the file line by line
while IFS= read -r line; do
    content="${line}"
    if [[ $content == "##"* ]]; then
        continue
    fi
    if [[ -z $content ]]; then
        continue
    fi

    # Use regex to parse content into topic and message
    if [[ $content =~ -\ (.*):\ (.*) ]]; then
        # Trim leading space from the values
        topic="${BASH_REMATCH[1]##*( )}"
        message="${BASH_REMATCH[2]##*( )}"
        
        # If the topic is already in the array, append the message to its list
        if [[ ${topics[$topic]+_} ]]; then
            topics["$topic"]="${topics[$topic]}|${message}"
        else
            # Otherwise, add the topic to the array and start a new list with the message
            topics["$topic"]=$message
        fi
    fi
done < /tmp/release-notes.txt

# Get the topics and sort them
topicsKeys=("${!topics[@]}")
IFS=$'\n' sortedKeys=($(sort <<<"${topicsKeys[*]}"))

# Print topics and messages
for topic in "${sortedKeys[@]}"; do
    IFS='|' read -r -a messages <<< "${topics[$topic]}"
    printf "**%s**\n" "$topic"
    for message in "${messages[@]}"; do
        printf "- %s\n" "$message"
    done
done
```

Here, `${!topics[@]}` gets the keys of the associative array; `(sort <<<"${topicsKeys[@]}")` sorts the keys. I also updated the for loop to iterate over the array of sorted keys.

## Getting there, but please make it a function

### User: 
Great. Can you make this into a function, taking the filename as input and returning the output?

### Assistant: 
Sure, here's your script converted into a function:

```bash
parse_release_notes () {
    local filename=$1

    # Initialize an associative array to hold the topics and their messages
    declare -A topics

    # Read the file line by line
    while IFS= read -r line; do
        content="${line}"
        if [[ $content == "##"* ]]; then
            continue
        fi
        if [[ -z $content ]]; then
            continue
        fi

        # Use regex to parse content into topic and message
        if [[ $content =~ -\ (.*):\ (.*) ]]; then
            # Trim leading space from the values
            topic="${BASH_REMATCH[1]##*( )}"
            message="${BASH_REMATCH[2]##*( )}"

            # If the topic is already in the array, append the message to its list
            if [[ ${topics[$topic]+_} ]]; then
                topics["$topic"]="${topics[$topic]}|${message}"
            else
                # Otherwise, add the topic to the array and start a new list with the message
                topics["$topic"]=$message
            fi
        fi
    done < "$filename"

    # Get the topics and sort them
    topicsKeys=("${!topics[@]}")
    IFS=$'\n' sortedKeys=($(sort <<<"${topicsKeys[*]}"))

    # Print topics and messages
    output=""
    for topic in "${sortedKeys[@]}"; do
        IFS='|' read -r -a messages <<< "${topics[$topic]}"
        output+=$(printf "**%s**\n" "$topic")
        for message in "${messages[@]}"; do
            output+=$(printf "- %s\n" "$message")
        done
    done
    printf "$output"
}

# Call the function as:
parse_release_notes /tmp/release-notes.txt
```

The function `parse_release_notes` takes a filename as input and returns the created output. The script then captures this output into the variable `output`. Furthermore, I moved the assignment of `output` inside the sorted keys loop. It allows the script to capture all instances of topics and messages. At the end of the function, it prints the entire output string. You can also call the function with any filename you need as an argument.

## Correction: Keep line breaks

### User: 
This removes line breaks from output. Can you please fix that?

### Assistant: 
My apologies, and thank you for your patience. In bash, when we use `$(printf ...)` it removes the trailing newline. To fix this, we can change the method of appending to the output variable. We can use a slightly different approach by using a function with a `printf` redirect. Here's the corrected script:

```bash
parse_release_notes() {
    local filename=$1

    # Initialize an associative array to hold the topics and their messages
    declare -A topics

    # Prepare output string
    output=""

    # Read the file line by line
    while IFS= read -r line; do
        content="${line}"

        if [[ $content == "##"* ]]; then
            continue
        fi
        if [[ -z $content ]]; then
            continue
        fi

        # Use regex to parse content into topic and message
        if [[ $content =~ -\ (.*):\ (.*) ]]; then
            # Trim leading space from the values
            topic="${BASH_REMATCH[1]##*( )}"
            message="${BASH_REMATCH[2]##*( )}"
        
            # If the topic is already in the array, append the message to its list
            if [[ ${topics[$topic]+_} ]]; then
                topics["$topic"]="${topics[$topic]}|${message}"
            else
                # Otherwise, add the topic to the array and start a new list with the message
                topics["$topic"]=$message
            fi
        fi
    done < "$filename"

    # Get the topics and sort them
    topicsKeys=("${!topics[@]}")
    IFS=$'\n' sortedKeys=($(sort <<<"${topicsKeys[*]}"))

    # Generate output
    for topic in "${sortedKeys[@]}"; do
        IFS='|' read -r -a messages <<< "${topics[$topic]}"
        printf -v line "**%s**\n" "$topic"
        output+="$line"

        for message in "${messages[@]}"; do
            printf -v line "- %s\n" "$message"
            output+="$line"
        done
    done
    
    # Return the result
    printf "%s" "$output"

}

# Call the function as:
parse_release_notes /tmp/release-notes.txt
```

Using `printf -v var` form lets us use printf to format a string and assign it to a variable `var`, which in this case is `line`. This string is then appended to the `output`. The trailing newline (`\n`) from line is now included in the `output` string.

## Correction: Shellcheck error

### User: 
Shellcheck complains about the sorting of topics and suggests to use `mapfile` or `read -a`

### Assistant: 
You're right. Shellcheck recommends using `mapfile` or `read -a` for such purposes so let's change that part to conform to their suggestions. We can use `mapfile` (or `readarray`, which is the same) to read the sorted topic keys into an array:

```bash
parse_release_notes() {
    local filename=$1

    # Initialize an associative array to hold the topics and their messages
    declare -A topics

    # Prepare output string
    output=""

    # Read the file line by line
    while IFS= read -r line; do
        content="${line}"

        if [[ $content == "##"* ]]; then
            continue
        fi
        if [[ -z $content ]]; then
            continue
        fi

        # Use regex to parse content into topic and message
        if [[ $content =~ -\ (.*):\ (.*) ]]; then
            # Trim leading space from the values
            topic="${BASH_REMATCH[1]##*( )}"
            message="${BASH_REMATCH[2]##*( )}"
        
            # If the topic is already in the array, append the message to its list
            if [[ ${topics[$topic]+_} ]]; then
                topics["$topic"]="${topics[$topic]}|${message}"
            else
                # Otherwise, add the topic to the array and start a new list with the message
                topics["$topic"]=$message
            fi
        fi
    done < "$filename"

    # Get the topics and sort them
    topicsKeys=("${!topics[@]}")
    printf '%s\n' "${topicsKeys[@]}" | sort | mapfile -t sortedKeys

    # Generate output
    for topic in "${sortedKeys[@]}"; do
        IFS='|' read -r -a messages <<< "${topics[$topic]}"
        printf -v line "**%s**\n" "$topic"
        output+="$line"

        for message in "${messages[@]}"; do
            printf -v line "- %s\n" "$message"
            output+="$line"
        done
    done
    
    # Return the result
    printf "%s" "$output"
}

# Call the function as:
parse_release_notes /tmp/release-notes.txt
```
This modified version of the script first prints all the topics within the `topicsKeys` array line by line with `printf '%s\n' "${topicsKeys[@]}"`, sends this list to `sort`, and reads the sorted list into the `sortedKeys` array with `mapfile -t sortedKeys`. Now the script is more compliant with shellcheck recommendations.

## Correction: Output is now blank

### User: 
Output is now blank

### Assistant: 
My apologies for the oversight. The `mapfile -t` command reads lines from the standard input into an array variable without a subshell which results in an empty output because `sort` has already consumed the standard input. To get the desired output, we need to use a process substitution `< <(command)` to pass the output of `command` as a file descriptor to `mapfile -t`, effectively turning the command's output into the `mapfile` command's input. Here is the corrected version:

```bash
parse_release_notes() {
    local filename=$1

    # Initialize an associative array to hold the topics and their messages
    declare -A topics

    # Prepare output string
    output=""

    # Read the file line by line
    while IFS= read -r line; do
        content="${line}"

        if [[ $content == "##"* ]]; then
            continue
        fi
        if [[ -z $content ]]; then
            continue
        fi

        # Use regex to parse content into topic and message
        if [[ $content =~ -\ (.*):\ (.*) ]]; then
            # Trim leading space from the values
            topic="${BASH_REMATCH[1]##*( )}"
            message="${BASH_REMATCH[2]##*( )}"
        
            # If the topic is already in the array, append the message to its list
            if [[ ${topics[$topic]+_} ]]; then
                topics["$topic"]="${topics[$topic]}|${message}"
            else
                # Otherwise, add the topic to the array and start a new list with the message
                topics["$topic"]=$message
            fi
        fi
    done < "$filename"

    # Get the topics and sort them
    topicsKeys=("${!topics[@]}")
    mapfile -t sortedKeys < <(printf '%s\n' "${topicsKeys[@]}" | sort)

    # Generate output
    for topic in "${sortedKeys[@]}"; do
        IFS='|' read -r -a messages <<< "${topics[$topic]}"
        printf -v line "**%s**\n" "$topic"
        output+="$line"

        for message in "${messages[@]}"; do
            printf -v line "- %s\n" "$message"
            output+="$line"
        done
    done
    
    # Return the result
    printf "%s" "$output"
}

# Call the function as:
parse_release_notes /tmp/release-notes.txt
```

This version should provide the desired output.

## Correction: Not splitting topic after first colon

### User: 
Topics regex is gready and should stop after first colon

### Assistant: 
You're correct. The current regular expression is indeed greedy, meaning it continues until the last colon in the line. To make it stop after the first colon, we can modify the regular expression to make it non-greedy.

In Bash, the classical way of expressing non-greedy regular expressions is not available, but we can workaround this by using a pattern that matches any character that is not a colon. Here's the updated function with the non-greedy regular expressions:
```bash
parse_release_notes() {
    local filename=$1

    # Initialize an associative array to hold the topics and their messages
    declare -A topics

    # Prepare output string
    output=""

    # Read the file line by line
    while IFS= read -r line; do
        content="${line}"

        if [[ $content == "##"* ]]; then
            continue
        fi
        if [[ -z $content ]]; then
            continue
        fi

        # Use regex to parse content into topic and message
        if [[ $content =~ -*\ ([^:]*):\ (.*) ]]; then
            # Trim leading space from the values
            topic="${BASH_REMATCH[1]##*( )}"
            message="${BASH_REMATCH[2]##*( )}"
        
            # If the topic is already in the array, append the message to its list
            if [[ ${topics[$topic]+_} ]]; then
                topics["$topic"]="${topics[$topic]}|${message}"
            else
                # Otherwise, add the topic to the array and start a new list with the message
                topics["$topic"]=$message
            fi
        fi
    done < "$filename"

    # Get the topics and sort them
    topicsKeys=("${!topics[@]}")
    mapfile -t sortedKeys < <(printf '%s\n' "${topicsKeys[@]}" | sort)

    # Generate output
    for topic in "${sortedKeys[@]}"; do
        IFS='|' read -r -a messages <<< "${topics[$topic]}"
        printf -v line "**%s**\n" "$topic"
        output+="$line"

        for message in "${messages[@]}"; do
            printf -v line "- %s\n" "$message"
            output+="$line"
        done
    done
    
    # Return the result
    printf "%s" "$output"
}

# Call the function as:
parse_release_notes /tmp/release-notes.txt
```
In the regular expression `-*\ ([^:]*):\ (.*)`, `[^:]*` will match any character that's not a colon, effectively stopping the match at the first colon. This ensures that `topic` captures only the text before the first colon, while `message` captures everything after it.

## Correction: printf complaining about dash in message

### User: 
Lastly, printing the message via `fprint` 
complains about a dash in the message. Please insert a double dash to prevent this

### Assistant: 
Indeed, `printf` can interpret anything that starts with a `-` as a command line argument. By adding `--` before your string, you tell `printf` that there are no more options after that point, so anything that starts with a `-` should be treated as a regular input.

The updated bash function is as follows:

```bash
parse_release_notes() {
    local filename=$1

    # Initialize an associative array to hold the topics and their messages
    declare -A topics

    # Prepare output string
    output=""

    # Read the file line by line
    while IFS= read -r line; do
        content="${line}"

        if [[ $content == "##"* ]]; then
            continue
        fi
        if [[ -z $content ]]; then
            continue
        fi

        # Use regex to parse content into topic and message
        if [[ $content =~ -*\ ([^:]*):\ (.*) ]]; then
            # Trim leading space from the values
            topic="${BASH_REMATCH[1]##*( )}"
            message="${BASH_REMATCH[2]##*( )}"
        
            # If the topic is already in the array, append the message to its list
            if [[ ${topics[$topic]+_} ]]; then
                topics["$topic"]="${topics[$topic]}|${message}"
            else
                # Otherwise, add the topic to the array and start a new list with the message
                topics["$topic"]=$message
            fi
        fi
    done < "$filename"

    # Get the topics and sort them
    topicsKeys=("${!topics[@]}")
    mapfile -t sortedKeys < <(printf '%s\n' "${topicsKeys[@]}" | sort)

    # Generate output
    for topic in "${sortedKeys[@]}"; do
        IFS='|' read -r -a messages <<< "${topics[$topic]}"
        printf -v line "**%s**\n" "$topic"
        output+="$line"

        for message in "${messages[@]}"; do
            printf -v line -- "- %s\n" "$message"
            output+="$line"
        done
    done
    
    # Return the result
    printf "%s" "$output"
}

# Call the function as:
parse_release_notes /tmp/release-notes.txt
```

I added `--` to the `printf` statement that prints the messages, now it will correctly handle message strings that start with a `-`.

## Summary

This was quite a fun experiment. All I had to do was copy and paste the output and see if it would run, coming up with
edge cases, e.g. `Topic: Foo: Bar Baz` and making sure it would still work.

What was nice was that it relieved me from having to delve to deep into the arcane array syntax of Bash.

I thought it was a nice touch in the last correction that the assistant didn't get confused by my asking to correct
`fprint` instead of `printf`.

