import os
import glob

def replace_in_file(file_path, old, new):
    with open(file_path, 'r') as f:
        content = f.read()
    if old in content:
        content = content.replace(old, new)
        with open(file_path, 'w') as f:
            f.write(content)
        print(f"Fixed {file_path}")

def fix_all():
    base_dir = "/Users/mohammeddilshadp/Desktop/Main project/My Own Projects/ClubSphere"
    for root, dirs, files in os.walk(base_dir):
        if '.dart_tool' in root or 'build' in root:
            continue
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                # Read content
                with open(path, 'r') as f:
                    content = f.read()
                
                new_content = content.replace('.withOpacity(', '.withValues(alpha: ')
                
                # groupValue and onChanged deprecation in flutter 3.32
                new_content = new_content.replace('anonKey:', 'publishableKey:')
                
                # Unused local var 'theme'
                if 'final theme = Theme.of(context);' in new_content and 'theme.' not in new_content.replace('final theme = Theme.of(context);', ''):
                    new_content = new_content.replace('final theme = Theme.of(context);\n', '')
                
                if 'final isGoingToRegister = path.startsWith(\'/register\');' in new_content:
                    new_content = new_content.replace('final isGoingToRegister = path.startsWith(\'/register\');', '')

                if new_content != content:
                    with open(path, 'w') as f:
                        f.write(new_content)
                    print(f"Updated {path}")

fix_all()
