echo "Enter a single word to prefix your project name:"
read -p "> " PROJECT_NAME

if [[ -z "$PROJECT_NAME" ]]; then
  echo "Error: Project name cannot be empty."
  exit 1
fi

set -u

# Clean old files if any
rm -rf ./pages ./public ./styles ./next.config.js ./package.json ./package-lock.json ./yarn.lock ./node_modules

npm init -y

npm install next react react-dom

mkdir -p pages/api styles public

# _app.jsx - load global styles
cat > ./pages/_app.jsx << EOF
import '../styles/globals.css'

export default function App({ Component, pageProps }) {
  return <Component {...pageProps} />
}
EOF

# index.jsx - main page
cat > ./pages/index.jsx << EOF
export default function Home() {
  return (
    <div className="welcome">
      Welcome to your first Next.js Application!
    </div>
  )
}
EOF

# globals.css - converted styles + fonts
cat > ./styles/globals.css << EOF
@import url('https://fonts.googleapis.com/css2?family=Nunito:wght@300&family=Quicksand&family=Roboto:wght@100&display=swap');

:root {
  --primary: #ffb400;
  --secondary: #00a6ed;
  --info: #7fb800;
  --warning: #f6511d;
  --white: #ffffff;
  --offWhite: #f2f2f3;
  --dark: #3b3b3b;
  --outline: #c3c0c0;
  --appBackground: #dddade;
}

body,
button,
input,
select,
textarea {
  font-family: "Nunito", sans-serif;
}

body {
  background-color: var(--appBackground);
  margin: 0;
}

h1, h2, h3, h4, h5, h6 {
  font-family: "Roboto", serif;
}

a {
  text-decoration: none;
  color: inherit;
}

a:visited {
  color: inherit;
}

input:focus {
  outline: none;
}

button {
  padding: 0.5rem 1rem;
  border: 1px solid transparent;
  border-radius: 0.5rem;
  color: var(--white);
  cursor: pointer;
}

.btn-primary {
  background-color: var(--primary);
}

.btn-primary:hover {
  background-color: #e5a000;
}

.btn-secondary {
  background-color: var(--secondary);
}

.btn-secondary:hover {
  background-color: #0097d7;
}

.btn-warning {
  background-color: var(--warning);
}

.btn-warning:hover {
  background-color: #e14617;
}

.btn-info {
  background-color: var(--info);
}

.btn-info:hover {
  background-color: #71a500;
}

.welcome {
  text-align: center;
  margin: 5rem 14rem;
  font-size: 4rem;
  color: aliceblue;
  font-weight: bold;
  text-shadow: 2px 3px 4px lightslategray;
}
EOF

# next.config.js - minimal config
cat > ./next.config.js << EOF
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
}

module.exports = nextConfig
EOF

# Example API route: register user
cat > ./pages/api/register.js << 'EOF'
export default function handler(req, res) {
  if (req.method === 'POST') {
    const { email, password, profilePic, isBusiness, isAdmin } = req.body;
    // Here you’d normally add user to DB, hash password, validation, etc.
    if (!email || !password) {
      return res.status(400).json({ error: "Email and password are required." });
    }
    // Just echo back for demo
    return res.status(201).json({ message: "User registered", user: { email, profilePic, isBusiness, isAdmin } });
  } else {
    res.setHeader('Allow', ['POST']);
    res.status(405).end(`Method ${req.method} Not Allowed`);
  }
}
EOF

# Example API route: login user
cat > ./pages/api/login.js << 'EOF'
export default function handler(req, res) {
  if (req.method === 'POST') {
    const { email, password } = req.body;
    // Normally verify user & password, generate token, etc.
    if (email === "test@example.com" && password === "password") {
      return res.status(200).json({ message: "Login successful", token: "fake-jwt-token" });
    } else {
      return res.status(401).json({ error: "Invalid credentials" });
    }
  } else {
    res.setHeader('Allow', ['POST']);
    res.status(405).end(`Method ${req.method} Not Allowed`);
  }
}
EOF

# Add npm scripts
npm set-script dev "next dev"
npm set-script build "next build"
npm set-script start "next start"

echo "Next.js project '${PROJECT_NAME}' created!"
echo ""
echo "Run the development server with:"
echo "  npm run dev"
echo ""
echo "API routes available:"
echo "  POST /api/register"
echo "  POST /api/login"
echo ""
echo "Open http://localhost:3000 to view your app."