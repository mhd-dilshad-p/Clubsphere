import os

files_to_fix = [
    'lib/features/dashboard/elections/vote_sheet.dart',
    'lib/features/dashboard/events/create_event_sheet.dart',
    'lib/features/dashboard/finance/add_finance_sheet.dart',
    'lib/features/auth/register/club_register_screen.dart'
]

for file_path in files_to_fix:
    if os.path.exists(file_path):
        with open(file_path, 'r') as f:
            content = f.read()
        
        # Replace context.mounted with mounted which is safe inside StatefulWidget
        content = content.replace('!context.mounted', '!mounted')
        
        with open(file_path, 'w') as f:
            f.write(content)
        print(f"Fixed mounted check in {file_path}")

