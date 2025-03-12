#!/bin/bash

# Create necessary directories and files
mkdir -p users patients doctors prescriptions messages appointments logs

touch symptoms_diseases.txt users.txt patients/bmi_history.txt disease_info.txt prescriptions.txt appointments.txt messages.txt

DB_FILE="medicine_db.txt"

#file permissions
chmod 700 users patients doctors prescriptions messages appointments logs

#User Authentication Function
authenticate_user() {
    echo "Enter Username:"
    read username
    echo "Enter Password:"
    read -s password
    
    if grep -q "^$username:$password" users.txt; then
        role=$(grep "^$username:$password" users.txt | cut -d: -f3)
        echo "Login successful as $role"
        
        if [[ "$role" == "patient" ]]; then
            patient_menu
        elif [[ "$role" == "doctor" ]]; then
            doctor_menu
        else
            echo "Invalid role found in user data!"
        fi
    else
        echo "Invalid credentials!"
    fi
}

#User Registration Function
register_user() {
    echo "Enter new username:"
    read username
    if grep -q "^$username:" users.txt; then
        echo "Username already exists!"
        return 1
    fi
    echo "Enter new password:"
    read -s password
    echo "Are you a Patient or a Doctor? (P/D)"
    read role
    if [[ "$role" == "P" ]]; then
        echo "$username:$password:patient" >> users.txt
        echo "Registration successful as Patient."
    elif [[ "$role" == "D" ]]; then
        echo "$username:$password:doctor" >> users.txt
        echo "Registration successful as Doctor."
    else
        echo "Invalid role!"
    fi
}

#PATIENT FEATURES
# BMI Calculator Function
calculate_bmi() {
    echo "Enter weight (kg):"
    read weight
    echo "Enter height (m):"
    read height
    bmi=$(echo "scale=2; $weight/($height*$height)" | bc)
    echo "Your BMI is: $bmi"

    if (( $(echo "$bmi < 18.5" | bc -l) )); then
        echo "Underweight - Increase your caloric intake."
    elif (( $(echo "$bmi < 25" | bc -l) )); then
        echo "Normal - Maintain your current lifestyle."
    elif (( $(echo "$bmi < 30" | bc -l) )); then
        echo "Overweight - Exercise more."
    else
        echo "Obese - Consult a doctor."
    fi

    echo "$username: $bmi" >> patients/bmi_history.txt
}

#Match Symptoms to Diseases
find_disease() {
    echo "Enter your symptoms separated by commas (e.g., fever, headache):"
    read symptoms
    matched_diseases=()
    
    while IFS= read -r line; do
        symptom_list=$(echo "$line" | cut -d: -f1)
        disease=$(echo "$line" | cut -d: -f2 | xargs)
        
        for symptom in ${symptoms//,/ }; do
            if [[ "$symptom_list" == *"$symptom"* ]]; then
                matched_diseases+=("$disease")
                break
            fi
        done
    done < symptoms_diseases.txt
    
    if [ ${#matched_diseases[@]} -eq 0 ]; then
        echo "No disease found for the given symptoms."
    else
        echo "Possible diseases based on symptoms:"
        select disease in "${matched_diseases[@]}" "Go Back"; do
            if [[ "$disease" == "Go Back" ]]; then
                break
            elif [[ -n "$disease" ]]; then
                display_disease_info "$disease"
                break
            else
                echo "Invalid choice!"
            fi
        done
    fi
}

#DISPLAY DISEASE INFO
display_disease_info() {
    disease=$1
    info=$(grep "^$disease:" disease_info.txt)
    
    if [[ -z "$info" ]]; then
        echo "No details found for $disease."
        return
    fi
    
    while true; do
        echo "Select an option for $disease:"
        echo "1. Details"
        echo "2. Medications"
        echo "3. Prevention"
        echo "4. Go Back"
        read -p "Choose an option: " option
        
        case $option in
            1) echo "Details: $(echo "$info" | cut -d: -f2)" ;;
            2) echo "Medications: $(echo "$info" | cut -d: -f3)" ;;
            3) echo "Prevention: $(echo "$info" | cut -d: -f4)" ;;
            4) break ;;
            *) echo "Invalid option!" ;;
        esac
    done
}

#DOCTOR FEATURES:
#Doctor Adds Symptom-Disease Data
add_symptom_disease() {
    echo "Enter symptoms (comma-separated):"
    read symptoms
    echo "Enter disease name:"
    read disease
    echo "$symptoms: $disease" >> symptoms_diseases.txt
    
    echo "Enter disease details:"
    read details
    echo "Enter medications:"
    read medications
    echo "Enter prevention measures:"
    read prevention
    
    echo "$disease:$details:$medications:$prevention" >> disease_info.txt
    echo "Symptom-Disease data added successfully."
}

# Add Prescription
add_prescription() {
    echo "Enter patient username:"
    read patient
    echo "Enter prescription details:"
    read prescription
    date=$(date "+%Y-%m-%d")
    echo "$patient:$prescription:$date" >> prescriptions.txt
    echo "Prescription added successfully."
}


#PATIENT FEATURES:
# View Prescriptions
search_prescription() {
    echo "Your Prescriptions:"
    grep "^$username:" prescriptions.txt | while IFS=: read -r user prescription date; do
        echo "Prescription: $prescription (Issued on: $date)"
    done || echo "No prescriptions found."
}


#Request Appointment
schedule_appointment() {
    echo "Enter doctor username:"
    read doctor
    date=$(date "+%Y-%m-%d")
    echo "$username requests an appointment with Dr. $doctor on $date" >> appointments.txt
    echo "Appointment request sent."
}

#DOCTOR+PATIENT FEATURES:
#Send Message
send_message() {
    echo "Enter doctor username:"
    read doctor
    echo "Enter your message:"
    read message
    date=$(date "+%Y-%m-%d")
    echo "$username to $doctor: $message on $date" >> messages.txt
    echo "Message sent successfully."
}

#DOCTOR & PATIENT FEATURES
#View Messages
view_messages() {
    echo "Your Messages:"
    grep "$username" messages.txt | while IFS= read -r line; do
        echo "$line"
    done || echo "No messages found."
}


#DOCTOR FEATURES:
# Step 14: View Appointments
view_appointments() {
    echo "Your Appointments:"
    grep "$username" appointments.txt | while IFS= read -r line; do
        echo "$line"
    done || echo "No appointments found."
}

#PATIENT FEATURES:
#TRIVIA GAME LIKE GUESSING GAME
play_trivia() {
    local error_count=0
    local tries=0

    echo "Welcome to the Trivia Game! You have 3 lives."
    
    # Question 1
    while true; do
        read -p "Q: Who invented penicillin? (Hint: Starts with an F) " answer
        if [[ "$answer" == "Fleming" ]]; then
            echo "Correct!"
            break
        elif [[ "$answer" == "stop" ]]; then
            echo "Game terminated."
            return
        else
            ((error_count++))
            ((tries++))
            echo "Wrong answer. Tries: $tries | Errors: $error_count"
            if [[ $error_count -ge 3 ]]; then
                echo "Sorry, better luck next time!"
                return
            fi
        fi
    done
    
    # Question 2
    while true; do
        read -p "Q: What is the fear of blood? (Hint: Ends with Phobia) " answer
        if [[ "$answer" == "Hemophobia" ]]; then
            echo "Correct!"
            break
        elif [[ "$answer" == "stop" ]]; then
            echo "Game terminated."
            return
        else
            ((error_count++))
            ((tries++))
            echo "Wrong answer. Tries: $tries | Errors: $error_count"
            if [[ $error_count -ge 3 ]]; then
                echo "Sorry, better luck next time!"
                return
            fi
        fi
    done
    
    # Question 3
    while true; do
        read -p "Q: What is the study of the heart? (Hint: Cardio) " answer
        if [[ "$answer" == "Cardiology" ]]; then
            echo "Correct!"
            echo "Congratulations! You completed the trivia game."
            return
        elif [[ "$answer" == "stop" ]]; then
            echo "Game terminated."
            return
        else
            ((error_count++))
            ((tries++))
            echo "Wrong answer. Tries: $tries | Errors: $error_count"
            if [[ $error_count -ge 3 ]]; then
                echo "Sorry, better luck next time!"
                return
            fi
        fi
    done
}
#DOCTOR+PATIENT:
display_medicines() {
    if [[ ! -s "$DB_FILE" ]]; then
        echo "No medicines in the database."
        return
    fi
    echo "Medicine Database:"
    echo "-----------------"
    cat "$DB_FILE"
    echo "-----------------"
}

#DOCTOR FEATURES:
update_medicine() {
    echo "Enter medicine name to update:"
    read med_name
    if ! grep -q "^$med_name " "$DB_FILE"; then
        echo "Medicine not found!"
        return
    fi
    echo "Enter new dose (e.g., 500mg):"
    read dose
    echo "Enter new quantity:"
    read quantity

    grep -v "^$med_name " "$DB_FILE" > temp.txt
    echo "$med_name $dose $quantity" >> temp.txt
    mv temp.txt "$DB_FILE"
    echo "Medicine database updated."
}
#ADD MEDICINE TO THE LIST MEDICINE_DB.TXT
add_medicine() {
    echo "Enter medicine name:"
    read med_name

    # Check if medicine already exists
    if grep -q "^$med_name " "$DB_FILE"; then
        echo "Medicine already exists! Use update instead."
        return
    fi

    echo "Enter dose (e.g., 500mg):"
    read dose
    echo "Enter quantity:"
    read quantity

    # Append new medicine to database
    echo "$med_name $dose $quantity" >> "$DB_FILE"
    echo "Medicine added successfully."
}

#For patients
health_tips() {
    tips=(
        "Drink plenty of water daily."
        "Exercise at least 30 minutes a day."
        "Get enough sleep (7-8 hours)."
        "Eat more fruits and vegetables."
        "Reduce sugar intake."
        "Take breaks from screens."
        "Manage stress with meditation."
    )
    random_tip=${tips[$RANDOM % ${#tips[@]}]}
    echo "Health Tip: $random_tip"
}

medicine_reminder() {
    echo "Medicine Reminder: Have you taken your medicine today? (yes/no)"
    read response
    if [[ "$response" == "yes" ]]; then
        echo "Great! Stay healthy!"
    else
        echo "Don't forget to take it!"
    fi
}


#MENU FOR USERS:
patient_menu() {
    while true; do
        echo "Patient Menu:"
        echo "1. Calculate BMI"
        echo "2. Search Prescription"
        echo "3. Request Appointment"
        echo "4. Send Message to Doctor"
        echo "5. Find Disease by Symptoms"
        echo "6. View Appointments"
        echo "7. View Messages"
	echo "8. Play Trivia!"
	echo "9. View availabe medicines in the BUP medical center"
        echo "10. Daily Health Tips!!"
	echo "11. Medicine reminder"
	echo "12. Logout"
        read choice
        case $choice in
            1) calculate_bmi ;;
            2) search_prescription ;;
            3) schedule_appointment ;;
            4) send_message ;;
            5) find_disease ;;
            6) view_appointments ;;
            7) view_messages ;;
	    8) play_trivia ;;
	    9) display_medicines ;;
	    10) health_tips ;;
	    11) medicine_reminder ;;
	    12) break ;;
            *) echo "Invalid option!" ;;
        esac
    done
}


doctor_menu() {
    while true; do
        echo "Doctor Menu:"
        echo "1. Add Symptoms-Disease Data"
        echo "2. Add Prescription"
        echo "3. View Appointments"
        echo "4. View Messages"
        echo "5. View Symptoms for a Disease"
	echo "6. View availabe medicines in the BUP medical center"
	echo "7. Update medicines in the BUP medical center"
	echo "8. Add medicine to the inventory"
        echo "9. Logout"
        read choice
        case $choice in
            1) add_symptom_disease ;;
            2) add_prescription ;;
            3) view_appointments ;;
            4) view_messages ;;
            5) find_disease ;;
	    6) display_medicines ;;
	    7) update_medicine ;;
	    8) add_medicine ;;
            9) break ;;
            *) echo "Invalid option!" ;;
        esac
    done
}


#Start Script
main_menu() {
    while true; do
        echo "Main Menu:"
        echo "1. Login"
        echo "2. Register"
        echo "3. Exit"
        read choice
        case $choice in
            1) authenticate_user ;;
            2) register_user ;;
            3) exit 0 ;;
            *) echo "Invalid option!" ;;
        esac
    done
}

# Start the script
main_menu


