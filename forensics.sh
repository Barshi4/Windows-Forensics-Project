#!/bin/bash

# /home/kali/projects/forensics/hello

# Checking if the user has root privileges
if [[ $(id -u) != 0 ]]; then
    echo "The script must run as root! try again."
    exit 1
fi

# checking if the required tools are installed
# instead of creating a function for each tool this function allows to pass the package/tool name to it 
check_tool(){

    # used a local variable so its only available here so other functions dont change it by accident
    # saves the first and second arguments passed to the function in case the package has a different name then the executable
    local tool="$1"
    local package="$2"

    # if the package name is different then the executable save it into $tool
    if [[ -z "$package" ]]; then
        package="$tool"
    fi

    # checking if the tools are installed and if not will attempt to install them
    if command -v "$tool" &> /dev/null; then
        echo "$tool is installed"
    else
        echo "$tool is not installed, installing..."
        apt update &> /dev/null && apt install -y "$package" &> /dev/null

        # checking if the tools installed successfully and if not will exit the script
        if command -v "$tool" &> /dev/null; then
            echo "$tool installed successfully"
        else
            echo "Error: failed to install $tool, exiting..."
            exit 1
        fi
    fi
}

# function to get the path to the the disk image or memory dump from the user
user_input(){
    while true; do
    read -r -p "Please enter the path to a memory dump or disk image: " file

    # checking whether the file exists and the script can read and use it
    if [[ -f "$file" && -r "$file" ]]; then
        echo "File exists and is readable"
        break
    else
        echo "File does not exist, please try again."
    fi
    done 
}

# creating the audit results folder
audit_results(){
    time_stamp=$(date +'%Y-%m-%d_%H-%M-%S')
    output_dir="./forensics_results/$time_stamp"
    
    # attempt to create the directories and if unable to will exit the script
    mkdir -p  "$output_dir" || exit 1

    echo "results will be saved to: $output_dir"
}


run_foremost(){

    # the command uses -i to specify the file to analyze and -o to specify the output directory
    if foremost -i "$file" -o "$output_dir/foremost_results"; then
        echo "foremost completed successfully"
    else
        echo "foremost failed"
    fi
}

run_binwalk(){

    # the command uses -e to extract embedded files or data and -C to specify the output directory
    if binwalk -e -C "$output_dir/binwalk_results" "$file"; then
        echo "binwalk completed successfully"
    else
        echo "binwalk failed"
    fi
}

run_bulk_extractor(){
    
    # the command uses -o to specify the output directory
    if bulk_extractor -o "$output_dir/bulk_results" "$file"; then
        echo "bulk_extractor completed successfully"
    else
        echo "bulk_extractor failed"
    fi
}

# checks if network traffic exists (.pcap file)
find_network_traffic(){
    
    # stores the expected .pcap file location in a local variable so other functions dont change it by accident
    local pcap="$output_dir/bulk_results/packets.pcap"

    # checks whether the pcap file exists and that its not empty
    if [[ -s "$pcap" ]]; then
        echo "Network capture found!"

        # outputs the pcap file location
        echo "Location: $pcap"

        # outputs the size of the pcap file (used stat because its more reliable then ls)
        ls -lh "$pcap" | awk '{print $5}'
    else
        echo "No network capture found."
    fi
}




user_input

check_tool foremost
check_tool binwalk
check_tool bulk_extractor bulk-extractor

audit_results

run_foremost
run_binwalk
run_bulk_extractor

find_network_traffic
