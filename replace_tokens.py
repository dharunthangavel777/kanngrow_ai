import os
import re

files_to_update = [
    r'c:\flutter projects\kangrow_ai\lib\widgets\cards\startup_idea_card.dart',
    r'c:\flutter projects\kangrow_ai\lib\screens\workspace_detail_screens.dart',
    r'c:\flutter projects\kangrow_ai\lib\screens\task_manager_screen.dart',
    r'c:\flutter projects\kangrow_ai\lib\screens\profile_screen.dart',
    r'c:\flutter projects\kangrow_ai\lib\screens\home_dashboard_screen.dart',
    r'c:\flutter projects\kangrow_ai\lib\providers\onboarding_provider.dart',
    r'c:\flutter projects\kangrow_ai\lib\providers\chat_provider.dart',
]

for filepath in files_to_update:
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Replace headers: { 'Authorization': 'Bearer mock-token' } with headers: await NetworkConfig.getHeaders()
        # Some are single line, some are multi-line. We'll do a regex replacement.
        # This regex matches:
        # headers: {
        #    'Authorization': 'Bearer mock-token',
        #    ...
        # }
        
        pattern1 = re.compile(r"headers:\s*\{[\s\S]*?'Authorization':\s*'Bearer mock-token',?[\s\S]*?\}")
        content = pattern1.sub("headers: await NetworkConfig.getHeaders()", content)
        
        # In chat_provider, it might be:
        # final headers = { 'Authorization': 'Bearer mock-token', 'Content-Type': 'application/json' };
        # Let's just find 'Authorization': 'Bearer mock-token'
        if 'chat_provider.dart' in filepath or 'onboarding_provider.dart' in filepath:
            pattern2 = re.compile(r"\{[\s\S]*?'Authorization':\s*'Bearer mock-token'[\s\S]*?\}")
            content = pattern2.sub("await NetworkConfig.getHeaders()", content)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
            
print("Replaced mock-token headers.")
