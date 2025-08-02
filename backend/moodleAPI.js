import express from "express";
import cors from "cors";
import { Sequelize, DataTypes } from "sequelize";
import fetch from "node-fetch";
import { URLSearchParams } from "url";

// Initialize Express
const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// SQLite Database Setup
const sequelize = new Sequelize({
  dialect: "sqlite",
  storage: "./database.sqlite",
  logging: false,
});

// Define Session Model
const Session = sequelize.define("Session", {
  sessionId: {
    type: DataTypes.STRING,
    primaryKey: true,
  },
  moodleToken: DataTypes.STRING,
  contentCheckerToken: DataTypes.STRING,
  createdAt: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
  expiresAt: DataTypes.DATE,
});

// Define Submission Model
const Submission = sequelize.define("Submission", {
  submissionId: {
    type: DataTypes.STRING,
    primaryKey: true,
  },
  courseId: DataTypes.STRING,
  assignmentId: DataTypes.STRING,
  title: DataTypes.STRING,
  content: DataTypes.TEXT,
  results: DataTypes.TEXT, // JSON string of analysis results
});

// Initialize Database
async function initializeDatabase() {
  try {
    await sequelize.authenticate();
    await sequelize.sync({ force: false }); // Set force:true to reset db on startup
    console.log("Database connected and synced");
  } catch (error) {
    console.error("Database connection error:", error);
  }
}

initializeDatabase();

class MoodleAPIService {
  constructor() {
    this.baseURL = "http://18.188.18.80/moodle";
    this.apiEndpoint = "http://18.188.18.80:3000/api/v1";
    this.credentials = {
      username: "teacher1",
      password: "Teacher1pass!",
    };
  }

  async authenticateMoodle(sessionId) {
    try {
      const response = await fetch(`${this.baseURL}/login/token.php`, {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: new URLSearchParams({
          username: this.credentials.username,
          password: this.credentials.password,
          service: "moodle_mobile_app",
        }),
      });

      const data = await response.json();
      if (data.token) {
        // Store in SQLite
        await Session.upsert({
          sessionId,
          moodleToken: data.token,
          expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 hours
        });
        return data.token;
      }
      throw new Error("Failed to authenticate with Moodle");
    } catch (error) {
      console.error("Moodle authentication error:", error);
      throw error;
    }
  }

  async fetchCourses(sessionId) {
    const session = await Session.findByPk(sessionId);
    if (!session || !session.moodleToken) {
      await this.authenticateMoodle(sessionId);
    }

    try {
      const token = session.moodleToken;
      const response = await fetch(
        `${this.baseURL}/webservice/rest/server.php`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
          body: new URLSearchParams({
            wstoken: token,
            wsfunction: "core_enrol_get_users_courses",
            moodlewsrestformat: "json",
            userid: 2, // teacher1 user ID
          }),
        }
      );

      return await response.json();
    } catch (error) {
      console.error("Error fetching courses:", error);
      throw error;
    }
  }

  async submitToContentChecker(sessionId, assignmentData) {
    try {
      const session = await Session.findByPk(sessionId);
      const response = await fetch(`${this.apiEndpoint}/content/submit`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${session?.contentCheckerToken || ""}`,
        },
        body: JSON.stringify({
          title: assignmentData.title,
          content_type: assignmentData.type,
          content: assignmentData.content,
          moodle_assignment_id: assignmentData.assignmentId,
          moodle_course_id: assignmentData.courseId,
        }),
      });

      const result = await response.json();

      // Store submission in SQLite
      await Submission.create({
        submissionId: result.submissionId,
        courseId: assignmentData.courseId,
        assignmentId: assignmentData.assignmentId,
        title: assignmentData.title,
        content: assignmentData.content,
        results: JSON.stringify(result),
      });

      return result;
    } catch (error) {
      console.error("Error submitting to content checker:", error);
      throw error;
    }
  }

  async getSubmissionResults(sessionId, submissionId) {
    try {
      const session = await Session.findByPk(sessionId);
      const submission = await Submission.findByPk(submissionId);

      if (submission) {
        return JSON.parse(submission.results);
      }

      // Fallback to API if not in database
      const response = await fetch(
        `${this.apiEndpoint}/analysis/results/${submissionId}`,
        {
          headers: {
            Authorization: `Bearer ${session?.contentCheckerToken || ""}`,
          },
        }
      );

      return await response.json();
    } catch (error) {
      console.error("Error fetching submission results:", error);
      throw error;
    }
  }
}

const moodleApiService = new MoodleAPIService();

// API Endpoints
app.post("/api/session", async (req, res) => {
  try {
    const sessionId = `session-${Date.now()}-${Math.random()
      .toString(36)
      .substr(2, 9)}`;
    await moodleApiService.authenticateMoodle(sessionId);
    res.json({ sessionId });
  } catch (error) {
    res.status(401).json({ error: error.message });
  }
});

app.get("/api/courses", async (req, res) => {
  try {
    const { sessionId } = req.query;
    if (!sessionId) {
      return res.status(400).json({ error: "Session ID required" });
    }
    const courses = await moodleApiService.fetchCourses(sessionId);
    res.json(courses);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post("/api/submit", async (req, res) => {
  try {
    const { sessionId, assignmentData } = req.body;
    if (!sessionId || !assignmentData) {
      return res
        .status(400)
        .json({ error: "Session ID and assignment data required" });
    }
    const result = await moodleApiService.submitToContentChecker(
      sessionId,
      assignmentData
    );
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get("/api/results/:submissionId", async (req, res) => {
  try {
    const { sessionId } = req.query;
    const { submissionId } = req.params;
    if (!sessionId || !submissionId) {
      return res
        .status(400)
        .json({ error: "Session ID and submission ID required" });
    }
    const results = await moodleApiService.getSubmissionResults(
      sessionId,
      submissionId
    );
    res.json(results);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: "Internal server error" });
});

app.listen(port, () => {
  console.log(`Moodle API service running on port ${port}`);
});
