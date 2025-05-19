module.exports = {
    apps: [
      {
        name: "fastapi-ai",
        script: "/home/deploy/venv/bin/python",
        args: "-m uvicorn main:app --host 0.0.0.0 --port 8000 --app-dir app-tuning",
        cwd: "/home/deploy/2-hertz-ai",
        env: {
          ENV: "dev",
          PYTHONIOENCODING: "utf-8",
          PYTHONPATH: "."
        },
        watch: false,
        restart_delay: 5000
      },
      {
        name: "chromadb",
        script: "/home/deploy/venv/bin/chroma",
        args: "run --port 8001 --path /home/deploy/chroma-data",
        interpreter: "none",
        exec_mode: "fork",
        env: {
          ENV: "prod"
        }
      }
    ]
  };