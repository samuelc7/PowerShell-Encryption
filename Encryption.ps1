# Create Encryption Certificate
New-SelfSignedCertificate -Subject message-encrypter -KeyUsage KeyEncipherment, DataEncipherment, KeyAgreement, -Type DocumentEncryptionCert

while ($true) {
    # Get User input
    $userInput = Read-Host "What would you like to do?`n1. Send Message`n2. Get Latest Message`n3. Get all Messages`n4. Quit`nYour Choice"

    # Determine what to do
    switch ($userInput) {
        1 { SendMessage }
        2 { GetLatestMessage }
        3 { GetAllMessages }
        4 { Write-Output "bye bye"; return }
        Default { Write-Output "That was not an option. Try again" }
    }
}

<#
This function gets a message from the user, encrypts it, and sends 
it to the messages.json file. 
#>
function SendMessage {
    $message = Read-Host "Your Message (don't worry, we'll encrypt it)"
    Write-Output "Encrypting message..."
    # Encrypt message
    $encryptedMessage = Encrypt -message $message
    $messagesList = Get-Content messages.json | ConvertFrom-Json
    # Create obj to add
    $toAdd = [PSCustomObject]@{
        "date" = Get-Date
        "message" = $encryptedMessage
    }
    $messagesList += $toAdd 
    $messagesJson = $messagesList | ConvertTo-Json
    # Remove content from file
    Clear-Content ./messages.json -Force
    # Add the new conent to the file 
    Add-Content ./messages.json $messagesJson 
    echo "Message sent"
}

<#
This will get the most recently added message from the 
messages.json file, decrypt it, and show the user through the 
console.
#>
function GetLatestMessage {
    Write-Output "Getting message..."
    $messagesList = Get-Content messages.json | ConvertFrom-Json
    $date = $messagesList[-1].date
    # Get encrypted message
    $encryptedMessage = $messagesList[-1].message | Get-CmsMessage
    Write-Output "Decrypting message..."
    # Decrypt
    $decryptedMessage = Decrypt -encryptedContent $encryptedMessage.Content
    Write-Output "Date: " + $date "`nMessage: " + $decryptedMessage
}

<#
This will get all the messages from the messages.json file, 
decrypt them, and show them to the user through the console.
#>
function GetAllMessages {
    Write-Output "Getting all messages..."
    $messagesList = Get-Content messages.json | ConvertFrom-Json
    $decryptedMessages = @()
    Write-Output "Decrypting messages..."
    foreach($message in $messagesList) {
        # Get encrypted content
        $encryptedMessage = $message.message | Get-CmsMessage
        # Decrypt the message
        $decryptedMessage = Decrypt -encryptedContent $encryptedMessage.Content
        $decryptedMessages += "`nDate: " + $message.date + "`nMessage: " +  $decryptedMessage + "`n"
    }
    Write-Output $decryptedMessages
}

<#
This will encrypt the given $message using an Encryption Certificate (which 
is looked up by the subject name.)
@Returns - The $message encrypted
#>
function Encrypt {
    param (
        $certificateSubject,
        [string] $message
    )
    return $message | Protect-CmsMessage -To $certificateSubject
}

<#
This will decrypt the $encryptedContent 
@Returns the decrypted content 
#>
function Decrypt {
    param (
        $encryptedContent
    )
    return Unprotect-CmsMessage -Content $encryptedContent
}