import express from "express";
import sqlite3pkg from "sqlite3";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import bodyParser from "body-parser";

const sqlite3 = sqlite3pkg.verbose();
const { hash: _hash, compare } = bcrypt;
const { verify, sign } = jwt;

// Initialize app and database
const app = express();
const db = new sqlite3.Database("./database.db");
const SECRET_KEY =
  process.env.SECRET_KEY ||
  "5da7ed21fddc03f0983011d83c6a95de620120deb335ffc2cc2aa05985a23fc0794310faed4aab83f0e41ecaf38fa28961ee6e2e6979ec4255d39f820af88505";

// Middleware
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Database schema initialization
const initializeDatabase = () => {
  const schema = [
    `CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT, 
      username TEXT UNIQUE, 
      password TEXT
    )`,
    `CREATE TABLE IF NOT EXISTS courses (
      id INTEGER PRIMARY KEY AUTOINCREMENT, 
      name TEXT
    )`,
    `CREATE TABLE IF NOT EXISTS assignments (
      id INTEGER PRIMARY KEY AUTOINCREMENT, 
      course_id INTEGER, 
      name TEXT, 
      FOREIGN KEY(course_id) REFERENCES courses(id)
    )`,
    `CREATE TABLE IF NOT EXISTS submissions (
      id INTEGER PRIMARY KEY AUTOINCREMENT, 
      assignment_id INTEGER, 
      student_written TEXT, 
      ai_generated TEXT, 
      ai_use_assessment TEXT, 
      assessment TEXT, 
      FOREIGN KEY(assignment_id) REFERENCES assignments(id)
    )`,
    `CREATE TABLE IF NOT EXISTS composition_breakdown (
      id INTEGER PRIMARY KEY AUTOINCREMENT, 
      submission_id INTEGER, 
      type TEXT, 
      section TEXT, 
      confidence TEXT, 
      details TEXT, 
      word_count INTEGER, 
      FOREIGN KEY(submission_id) REFERENCES submissions(id)
    )`,
    `CREATE TABLE IF NOT EXISTS logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT, 
      submission_id INTEGER, 
      timestamp TEXT, 
      type TEXT, 
      content TEXT, 
      matched BOOLEAN, 
      similarity TEXT, 
      FOREIGN KEY(submission_id) REFERENCES submissions(id)
    )`,
    `CREATE TABLE IF NOT EXISTS contents (
      id INTEGER PRIMARY KEY AUTOINCREMENT, 
      submission_id INTEGER, 
      title TEXT, 
      body TEXT, 
      FOREIGN KEY(submission_id) REFERENCES submissions(id)
    )`,
  ];

  db.serialize(() => {
    schema.forEach((sql) => db.run(sql));
  });
};

initializeDatabase();

// Authentication middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1];

  if (!token) return res.sendStatus(401);

  verify(token, SECRET_KEY, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
};

// Helper function for database operations
const dbRun = (sql, params) => {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function (err) {
      if (err) reject(err);
      else resolve(this);
    });
  });
};

const dbGet = (sql, params) => {
  return new Promise((resolve, reject) => {
    db.get(sql, params, (err, row) => {
      if (err) reject(err);
      else resolve(row);
    });
  });
};

const dbAll = (sql, params) => {
  return new Promise((resolve, reject) => {
    db.all(sql, params, (err, rows) => {
      if (err) reject(err);
      else resolve(rows);
    });
  });
};

// Auth Routes
app.post("/register", async (req, res) => {
  try {
    const { username, password } = req.body;
    const hash = await _hash(password, 10);
    const result = await dbRun(
      "INSERT INTO users (username, password) VALUES (?, ?)",
      [username, hash]
    );
    res.json({ id: result.lastID, username });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.post("/auth/login", async (req, res) => {
  try {
    const { username, password } = req.body;
    const user = await dbGet("SELECT * FROM users WHERE username = ?", [
      username,
    ]);

    if (!user) return res.status(400).json({ error: "User not found" });

    const valid = await compare(password, user.password);
    if (!valid) return res.status(403).json({ error: "Invalid credentials" });

    const token = sign({ id: user.id, username: user.username }, SECRET_KEY);
    console.log("User logged in successfuly!");
    res.json({ success: true, token: token });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Course Routes
app.post("/courses", authenticateToken, async (req, res) => {
  try {
    const { name } = req.body;
    const result = await dbRun("INSERT INTO courses (name) VALUES (?)", [name]);
    res.json({ id: result.lastID, name });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.get("/courses", authenticateToken, async (req, res) => {
  try {
    const rows = await dbAll("SELECT * FROM courses", []);
    res.json(rows);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// Assignment Routes
app.post("/assignments", authenticateToken, async (req, res) => {
  try {
    const { course_id, name } = req.body;
    const result = await dbRun(
      "INSERT INTO assignments (course_id, name) VALUES (?, ?)",
      [course_id, name]
    );
    res.json({ id: result.lastID, course_id, name });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// Submission Routes
app.post("/submissions", authenticateToken, async (req, res) => {
  try {
    const {
      assignment_id,
      student_written,
      ai_generated,
      ai_use_assessment,
      assessment,
      compositionBreakdown = [],
      logs = [],
      content = {},
    } = req.body;

    // Insert main submission
    const result = await dbRun(
      `INSERT INTO submissions (
        assignment_id, 
        student_written, 
        ai_generated, 
        ai_use_assessment, 
        assessment
      ) VALUES (?, ?, ?, ?, ?)`,
      [
        assignment_id,
        student_written,
        ai_generated,
        ai_use_assessment,
        assessment,
      ]
    );
    const submissionId = result.lastID;

    // Insert related data in parallel
    await Promise.all([
      ...compositionBreakdown.map((cb) =>
        dbRun(
          `INSERT INTO composition_breakdown (
            submission_id, 
            type, 
            section, 
            confidence, 
            details, 
            word_count
          ) VALUES (?, ?, ?, ?, ?, ?)`,
          [
            submissionId,
            cb.type,
            cb.section,
            cb.confidence,
            cb.details,
            cb.wordCount,
          ]
        )
      ),
      ...logs.map((log) =>
        dbRun(
          `INSERT INTO logs (
            submission_id, 
            timestamp, 
            type, 
            content, 
            matched, 
            similarity
          ) VALUES (?, ?, ?, ?, ?, ?)`,
          [
            submissionId,
            log.timestamp,
            log.type,
            log.content,
            log.matched,
            log.similarity,
          ]
        )
      ),
      dbRun(
        "INSERT INTO contents (submission_id, title, body) VALUES (?, ?, ?)",
        [submissionId, content.title, content.body]
      ),
    ]);

    res.json({ id: submissionId });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// Get full course data
app.get("/courses/:id/full", authenticateToken, async (req, res) => {
  try {
    const courseId = req.params.id;
    const assignments = await dbAll(
      "SELECT * FROM assignments WHERE course_id = ?",
      [courseId]
    );

    const courseData = {
      id: courseId,
      assignments: await Promise.all(
        assignments.map(async (assignment) => {
          const submissions = await dbAll(
            "SELECT * FROM submissions WHERE assignment_id = ?",
            [assignment.id]
          );

          assignment.submissions = await Promise.all(
            submissions.map(async (submission) => {
              const [compositionBreakdown, logs, content] = await Promise.all([
                dbAll(
                  "SELECT * FROM composition_breakdown WHERE submission_id = ?",
                  [submission.id]
                ),
                dbAll("SELECT * FROM logs WHERE submission_id = ?", [
                  submission.id,
                ]),
                dbGet("SELECT * FROM contents WHERE submission_id = ?", [
                  submission.id,
                ]),
              ]);

              return {
                ...submission,
                compositionBreakdown,
                logs,
                content,
              };
            })
          );

          return assignment;
        })
      ),
    };

    res.json(courseData);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Add this endpoint to your existing server code
app.get("/courses/all/nested", authenticateToken, async (req, res) => {
  try {
    // Get all courses
    const courses = await dbAll("SELECT * FROM courses", []);

    // Prepare the response structure
    const response = {};

    // Process each course
    for (const course of courses) {
      const courseKey = course.name;
      response[courseKey] = {};

      // Get assignments for this course
      const assignments = await dbAll(
        "SELECT * FROM assignments WHERE course_id = ?",
        [course.id]
      );

      // Process each assignment
      for (const assignment of assignments) {
        const assignmentKey = assignment.name;
        response[courseKey][assignmentKey] = {};

        // Get submissions for this assignment
        const submissions = await dbAll(
          "SELECT * FROM submissions WHERE assignment_id = ?",
          [assignment.id]
        );

        // Process each submission
        for (const submission of submissions) {
          const submissionKey = `Submission ${submission.id}`;
          response[courseKey][assignmentKey][submissionKey] = {};

          // Get composition breakdown
          const compositionBreakdown = await dbAll(
            "SELECT * FROM composition_breakdown WHERE submission_id = ?",
            [submission.id]
          );

          // Get logs
          const logs = await dbAll(
            "SELECT * FROM logs WHERE submission_id = ?",
            [submission.id]
          );

          // Get content
          const content = await dbGet(
            "SELECT * FROM contents WHERE submission_id = ?",
            [submission.id]
          );

          // Build the submission object
          response[courseKey][assignmentKey][submissionKey] = {
            compositionBreakdown: compositionBreakdown.map((cb) => ({
              type: cb.type,
              section: cb.section,
              confidence: cb.confidence,
              details: cb.details,
              wordCount: cb.word_count,
            })),
            "Student written": `${Math.round(
              (1 - (submission.ai_generated || 0)) * 100
            )}%`,
            "AI generated": `${Math.round(
              (submission.ai_generated || 0) * 100
            )}%`,
            "AI Use Assessment": submission.ai_use_assessment,
            logs: logs.map((log) => ({
              timestamp: log.timestamp,
              type: log.type,
              content: log.content,
              matched: Boolean(log.matched),
              similarity: log.similarity,
            })),
            Assessment: submission.assessment,
            content: {
              title: content?.title || "",
              body: content?.body || "",
            },
          };
        }
      }
    }

    res.json(response);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
