*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Dialogs


*** Variables ***
${RECEIPT_PATH}=    ${OUTPUT_DIR}${/}Receipts


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${user_input}=    Collect file download URL from user
    Download the Orders File    ${user_input}
    ${orders}=    Get Orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Order Failure Protection
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    Close Browser


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Collect file download URL from user
    Add text input    url    label=Enter URL for Data File
    ${response}=    Run dialog
    RETURN    ${response.url}

Download the Orders File
    [Arguments]    ${user_input}
    Download    ${user_input}    overwrite=True

Get Orders
    ${orders}=    Read table from CSV    orders.csv
    RETURN    ${orders}

Loop the Orders
    [Arguments]    ${orders}
    FOR    ${row}    IN    @{orders}
        Log    ${row}
    END

Close the annoying modal
    Click Button    css:button.btn.btn-dark

Fill the Form
    [Arguments]    ${row}
    Select From List By Value    css:#head    ${row}[Head]
    Select Radio Button    body    id-body-${row}[Body]
    Input Text    css:input[type='number'][placeholder='Enter the part number for the legs']    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the Robot
    Click Button    preview

Submit the order
    Click Button    order
    Wait Until Page Contains Element    CSS:#receipt    timeout=3s

Order Failure Protection
    Wait Until Keyword Succeeds    5x    1s    Submit the order

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    CSS:#receipt
    ${receipt_html}=    Get Element Attribute    CSS:#receipt    outerHTML
    ${pdf}=    Set Variable    ${RECEIPT_PATH}${/}${order_number}.pdf
    Html To Pdf    ${receipt_html}    ${pdf}
    RETURN    ${pdf}

Take a screenshot of the robot
    [Arguments]    ${file_name}
    ${screenshot}=    Set Variable    ${OUTPUT_DIR}${/}Screenshots${/}${file_name}.png
    ${robot_image}=    Set Variable    CSS:#robot-preview-image
    Wait Until Element Is Visible    ${robot_image}
    Screenshot    ${robot_image}    ${screenshot}
    RETURN    ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close Pdf    ${pdf}

Go to order another robot
    Click Button When Visible    CSS:#order-another

Create a ZIP file of the receipts
    ${zip_file}=    Set Variable    ${OUTPUT_DIR}${/}PDF_Archive.zip
    Archive Folder With Zip    ${RECEIPT_PATH}    ${zip_file}
