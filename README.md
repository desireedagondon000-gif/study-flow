
# StudyFlow 
A simple study planning application designed to help students organize tasks, manage subjects, and track their academic progress through an intuitive Kanban-style dashboard.

# Features

### Kanban Style Task Manager: 
A structured task management interface that allows users to visualize their study workload across "To Do," "In Progress," and "Done" states with manual status transitions.

### Progress Tracking: 
Provides a clear, real-time overview of academic progress by calculating task completion rates and subject-specific workload distribution.

### Study Session Timer: 
An integrated focus tool that allows users to start and manage study sessions, helping them maintain productivity on specific tasks.

### Cloud Sync: 
Backend integration with Supabase, ensuring secure data persistence and synchronization of tasks across sessions.

### Reactive State Management: 
Built with Riverpod to handle data updates efficiently, ensuring the UI remains perfectly in sync with the database. 

### Tech Stack
- Language/Framework: Flutter (Dart)

- Backend: Supabase (Auth & Database)

- State Management: Riverpod

- UI/UX: Implemented a modern & minimalistic design 



### How to Run
- Clone this repository: git clone [YOUR_REPO_URL]

- Install dependencies: flutter pub get

- Configure your Supabase environment variables.

- Run the app: flutter run


---


# Project Structure Overview

## auth Folder
Includes auth_provider.dart and login/signup screens; this folder manages all user authentication logic and session security.

## models Folder 
Contains task_model.dart; this is where the data structure and schema for the  tasks are defined.

## pages Folder 
Houses all UI screens like dashboard_page.dart and kanban_board.dart; this is the visual layer of the app.

## providers Folder
Contains tasks_provider.dart; this handles the global application state and real-time synchronization of the task data.

## widgets Folder
Includes app_header.dart; this folder holds reusable UI components to ensure design consistency across the app.

## main.dart 
The root of the application; it initializes the app, providers, and the initial routing.

---

# SCREENS:

### Landing Page: 
The entry point for users, featuring a clean, minimal design and a "Get Started" call-to-action.
<img src="assets/screenshots/profile.png" width="400"> 

---

### Login/Signup/Reset: 
Secure authentication flows with simple, consistent UI for managing account access.

<img src="assets/screenshots/login.png" width="400"> 
<img src="assets/screenshots/signup.png" width="400"> 
<img src="assets/screenshots/reset.png" width="400"> 

---

### Dashboard: 
The central hub providing a high-level overview of progress, total tasks, and completion statistics.

<img src="assets/screenshots/dashboard.png" width="400"> 

---

### Kanban Board: 
A drag-and-drop-ready task manager to visualize workflow states (To Do, In Progress, Done).

<img src="assets/screenshots/kanban.png" width="400"> 

---

### Study Sessions: 
An integrated focus tool allowing users to start study timers based on their specific subjects.

<img src="assets/screenshots/study.png" width="400"> 

---

### Pomodoro Timer: 
A focused, utility-driven overlay to keep users productive during active study sessions.

<img src="assets/screenshots/pomodoro.png" width="400"> 

---

### Profile: 
A personalized user hub for account history and icon-based customization.

<img src="assets/screenshots/profile.png" width="400"> 

---