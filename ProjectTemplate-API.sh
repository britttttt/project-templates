if ! command -v poetry &> /dev/null; then
  echo "Poetry not found. Installing Poetry..."
  curl -sSL https://install.python-poetry.org | python3 -
  export PATH="$HOME/.local/bin:$PATH"
  
echo "Enter a single word to prefix your project name and API app name:"
read -p "> " PROJECT_NAME

if [[ -z "$PROJECT_NAME" ]]; then
  echo "Error: Project name cannot be empty."
  exit 1
fi

curl -L -s 'https://raw.githubusercontent.com/github/gitignore/master/Python.gitignore' > .gitignore
echo 'db.sqlite3' >> .gitignore

# Initialize poetry project with defaults (no interactive prompts)
poetry init -n

# Add dependencies
poetry add django djangorestframework django-cors-headers
poetry add --dev autopep8 pylint pylint-django

poetry run django-admin startproject "${PROJECT_NAME}project" .
poetry run python3 manage.py startapp "${PROJECT_NAME}api"

mkdir -p ./.vscode
mkdir -p "./${PROJECT_NAME}api/fixtures"
mkdir -p "./${PROJECT_NAME}api/models"
touch "./${PROJECT_NAME}api/models/__init__.py"
mkdir -p "./${PROJECT_NAME}api/views"
touch "./${PROJECT_NAME}api/views/__init__.py"
touch "./${PROJECT_NAME}api/views/auth.py"

rm -f "./${PROJECT_NAME}api/views.py"
rm -f "./${PROJECT_NAME}api/models.py"

cat > ./.vscode/launch.json << EOF
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: Django",
            "type": "python",
            "request": "launch",
            "program": "\${workspaceFolder}/manage.py",
            "args": ["runserver"],
            "django": true,
            "autoReload":{
                "enable": true
            }
        }
    ]
}
EOF

cat > ./.vscode/settings.json << EOF
{
    "pylint.args": [
        "--disable=W0105,E1101,W0614,C0111,C0301",
        "--load-plugins=pylint_django",
        "--django-settings-module=${PROJECT_NAME}project.settings",
        "--max-line-length=120"
    ]
}
EOF

cat > "./${PROJECT_NAME}project/settings.py" << EOF
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = 'django-insecure-x9yg09-pv69(#mz@!n(1&c_rxvks#3*v&#vx!%t39p(n(f0gbb'

DEBUG = True

ALLOWED_HOSTS = []

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'rest_framework.authtoken',
    'corsheaders',
    '${PROJECT_NAME}api',
]

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework.authentication.TokenAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}

CORS_ORIGIN_WHITELIST = (
    'http://localhost:3000',
    'http://127.0.0.1:3000',
    'http://localhost:5173',
    'http://127.0.0.1:5173',
)

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = '${PROJECT_NAME}project.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = '${PROJECT_NAME}project.wsgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True
STATIC_URL = 'static/'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
EOF

cat > "./${PROJECT_NAME}project/urls.py" << EOF
from django.contrib import admin
from django.urls import include, path
from rest_framework import routers
from ${PROJECT_NAME}api.views import register_user, login_user

router = routers.DefaultRouter(trailing_slash=False)

urlpatterns = [
    path('', include(router.urls)),
    path('register', register_user),
    path('login', login_user),
    path('admin/', admin.site.urls),
]
EOF

cat > ./seed_database.sh << EOF
#!/bin/bash

rm -f db.sqlite3
rm -rf "./${PROJECT_NAME}api/migrations"
poetry run python3 manage.py migrate
poetry run python3 manage.py makemigrations ${PROJECT_NAME}api
poetry run python3 manage.py migrate ${PROJECT_NAME}api
poetry run python3 manage.py loaddata users
poetry run python3 manage.py loaddata tokens
EOF

chmod +x ./seed_database.sh

cat > .pylintrc << EOF
[FORMAT]
good-names=i,j,ex,pk

[MESSAGES CONTROL]
disable=broad-except,imported-auth-user,missing-class-docstring,no-self-use,abstract-method

[MASTER]
disable=C0114,
EOF

poetry run python3 manage.py migrate

git init
git add --all
git commit -m "Initial commit"

echo "**********************************"
echo ""
echo "Open your pyproject.toml and verify the Python version and dependencies."
echo ""
echo "To activate the virtual environment, run: poetry shell"
echo "To run commands inside the environment without activating, use: poetry run <command>"
echo ""
echo "**********************************"