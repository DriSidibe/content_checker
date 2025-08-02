// lib/utils/constants.dart
final List<String> courses = [
  'CS 101 - Introduction to Programming',
  'CS 201 - Data Structures',
  'ENG 102 - Academic Writing',
  'PHIL 150 - Ethics',
];

final Map<String, List<String>> courseAssignments = {
  'CS 101 - Introduction to Programming': [
    'Assignment 1: Hello World',
    'Assignment 2: Loops and Functions',
    'Assignment 3: Data Types',
  ],
  'CS 201 - Data Structures': [
    'Assignment 1: Arrays and Lists',
    'Assignment 2: Linked Lists',
    'Assignment 3: Trees and Graphs',
  ],
  'ENG 102 - Academic Writing': [
    'Essay 1: Argumentative Writing',
    'Essay 2: Research Paper',
    'Essay 3: Literary Analysis',
  ],
  'PHIL 150 - Ethics': [
    'Essay 1: Ethical Dilemmas',
    'Essay 2: Moral Philosophy',
    'Essay 3: Applied Ethics',
  ],
};

final Map<String, List<String>> assignmentSubmissions = {
  'Essay 1: Argumentative Writing': [
    'Student 1 - Sarah Johnson',
    'Student 2 - Mike Chen',
    'Student 3 - Emma Rodriguez',
    'Student 4 - David Kim',
  ],
  'Essay 2: Research Paper': [
    'Student 1 - Sarah Johnson',
    'Student 2 - Mike Chen',
    'Student 3 - Emma Rodriguez',
  ],
};

final List<Map<String, dynamic>> sampleLogs = [
  {
    'timestamp': '6/10/25, 1:03PM',
    'content':
        'Can you help me structure an essay about AI ethics in education?',
    'type': 'student',
    'matched': false,
  },
  {
    'timestamp': '6/10/25, 1:03PM',
    'content':
        'I\'d be happy to help you structure an essay on AI ethics in education. Here\'s a suggested approach: Morbi et tincidunt ligula. Sed vestibulum ex vitae urna posuere, vitae feugiat turpis malesuada.',
    'type': 'ai',
    'matched': true,
    'similarity': '94%',
  },
  {
    'timestamp': '6/10/25, 1:25PM',
    'content': 'What are some key points about AI in classrooms?',
    'type': 'student',
    'matched': false,
  },
  {
    'timestamp': '6/10/25, 1:25PM',
    'content':
        'Key considerations include: Aenean fringilla nulla nec velit sagittis, sed posuere sem pharetra. Praesent blandit velit vitae velit dictum dapibus.',
    'type': 'ai',
    'matched': true,
    'similarity': '97%',
  },
  {
    'timestamp': '6/11/25, 6:28PM',
    'content': 'Help me write a conclusion paragraph',
    'type': 'student',
    'matched': false,
  },
  {
    'timestamp': '6/11/25, 6:28PM',
    'content':
        'For your conclusion, consider: Vestibulum eget viverra elit. Curabitur a justo tempor, ultrices lorem nec, congue velit. Aenean volutpat vitae arcu sed varius.',
    'type': 'ai',
    'matched': true,
    'similarity': '91%',
  },
];

final List<Map<String, dynamic>> compositionBreakdown = [
  {
    'section': 'Title & Introduction',
    'type': 'human-written',
    'confidence': '95%',
    'wordCount': 87,
    'details': 'Original phrasing and structure',
  },
  {
    'section': 'Paragraph 1',
    'type': 'ai-assisted',
    'confidence': '78%',
    'wordCount': 156,
    'details': 'AI-generated phrases integrated with student writing',
  },
  {
    'section': 'Paragraph 2',
    'type': 'ai-assisted',
    'confidence': '82%',
    'wordCount': 134,
    'details': 'Structure assistance with human modifications',
  },
  {
    'section': 'Paragraph 3',
    'type': 'ai-assisted',
    'confidence': '85%',
    'wordCount': 148,
    'details': 'AI-suggested content with student adaptation',
  },
  {
    'section': 'Conclusion',
    'type': 'human-written',
    'confidence': '92%',
    'wordCount': 98,
    'details': 'Student\'s original synthesis and reflection',
  },
];
