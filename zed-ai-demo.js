// Zed AI Integration Demo File
// This file contains various coding scenarios to test your local AI setup
// Open this in Zed and try the AI features!

console.log("🚀 Welcome to Zed AI Demo!");

// ====================
// 1. CODE COMPLETION TEST
// ====================
// Try typing the start of a function and let AI complete it
// Example: Start typing "function calculateFib" and see what happens

function calculateFibonacci(n) {
    // Ask AI to complete this function implementation
    // Select this comment and ask: "Implement fibonacci sequence"
}

// ====================
// 2. BUG DETECTION TEST
// ====================
// This code has intentional bugs - ask AI to find them
const buggyFunction = (arr) => {
    let sum = 0;
    for (let i = 0; i <= arr.length; i++) {  // Bug: should be < not <=
        sum += arr[i];
    }
    return sum;
};

// Missing semicolon bug
const user = {
    name: "John",
    age: 30
    email: "john@example.com"  // Bug: missing comma
};

// ====================
// 3. CODE EXPLANATION TEST
// ====================
// Select this complex code and ask AI to explain it
const debounce = (func, delay) => {
    let timeoutId;
    return (...args) => {
        clearTimeout(timeoutId);
        timeoutId = setTimeout(() => func.apply(this, args), delay);
    };
};

// ====================
// 4. REFACTORING TEST
// ====================
// Ask AI to refactor this repetitive code
function processUserData(userData) {
    if (userData.name === null || userData.name === undefined || userData.name === "") {
        userData.name = "Unknown";
    }
    if (userData.email === null || userData.email === undefined || userData.email === "") {
        userData.email = "no-email@example.com";
    }
    if (userData.age === null || userData.age === undefined || userData.age === "") {
        userData.age = 0;
    }
    return userData;
}

// ====================
// 5. ALGORITHM CHALLENGE
// ====================
// Ask AI to implement these algorithms
function quickSort(array) {
    // Ask: "Implement quicksort algorithm here"
}

function binarySearch(array, target) {
    // Ask: "Implement binary search algorithm"
}

// ====================
// 6. DOCUMENTATION TEST
// ====================
// Ask AI to generate JSDoc comments for this function
function complexDataProcessor(data, options = {}) {
    const {
        sortBy = 'id',
        filterFn = null,
        transformFn = null,
        groupBy = null
    } = options;

    let result = [...data];

    if (filterFn) {
        result = result.filter(filterFn);
    }

    if (transformFn) {
        result = result.map(transformFn);
    }

    if (sortBy) {
        result.sort((a, b) => a[sortBy] - b[sortBy]);
    }

    if (groupBy) {
        return result.reduce((groups, item) => {
            const key = item[groupBy];
            groups[key] = groups[key] || [];
            groups[key].push(item);
            return groups;
        }, {});
    }

    return result;
}

// ====================
// 7. ERROR HANDLING TEST
// ====================
// Ask AI to add proper error handling
async function fetchUserData(userId) {
    const response = await fetch(`/api/users/${userId}`);
    const data = await response.json();
    return data.user;
}

// ====================
// 8. OPTIMIZATION TEST
// ====================
// Ask AI to optimize this inefficient code
function findDuplicates(arr) {
    const duplicates = [];
    for (let i = 0; i < arr.length; i++) {
        for (let j = i + 1; j < arr.length; j++) {
            if (arr[i] === arr[j] && !duplicates.includes(arr[i])) {
                duplicates.push(arr[i]);
            }
        }
    }
    return duplicates;
}

// ====================
// 9. MODERN JS CONVERSION
// ====================
// Ask AI to convert this old JS to modern ES6+
function OldStyleConstructor(name, age) {
    this.name = name;
    this.age = age;
}

OldStyleConstructor.prototype.greet = function() {
    return "Hello, I'm " + this.name;
};

OldStyleConstructor.prototype.isAdult = function() {
    return this.age >= 18;
};

// ====================
// 10. TEST GENERATION
// ====================
// Ask AI to generate unit tests for this function
function calculator(a, b, operation) {
    switch (operation) {
        case 'add':
            return a + b;
        case 'subtract':
            return a - b;
        case 'multiply':
            return a * b;
        case 'divide':
            return b !== 0 ? a / b : null;
        default:
            return null;
    }
}

// ====================
// HOW TO USE THIS FILE:
// ====================
/*
1. Open Zed
2. Load this file: zed zed-ai-demo.js
3. Try these AI features:

   📝 INLINE COMPLETION:
   - Start typing code and watch AI complete it

   💬 AI CHAT (Cmd+Shift+A):
   - Select code and ask: "Explain this code"
   - Ask: "Find bugs in this function"
   - Ask: "Refactor this to be more efficient"
   - Ask: "Add error handling to this function"
   - Ask: "Generate unit tests for this"

   🔍 SPECIFIC TESTS:
   - Select the buggyFunction and ask AI to find the bugs
   - Select the debounce function and ask for explanation
   - Select processUserData and ask for refactoring
   - Ask AI to implement the empty algorithm functions
   - Ask AI to add JSDoc to complexDataProcessor
   - Ask AI to optimize findDuplicates
   - Ask AI to modernize OldStyleConstructor

   🎯 CONVERSATION STARTERS:
   - "How can I make this code more readable?"
   - "What are potential security issues here?"
   - "How would you test this function?"
   - "Can you add TypeScript types to this?"
   - "What design patterns could improve this code?"

4. Available Models:
   - CodeLlama 13B (default) - Best for code completion/debugging
   - Llama 3.1 8B - Great for explanations and documentation
   - Llama 3.2 3B - Fastest for quick suggestions

5. Remember:
   ✅ Everything runs locally - complete privacy
   ✅ No API costs - just electricity
   ✅ Works offline
   ✅ Unlimited usage
*/

// Test your setup by asking AI about any of the code above!
console.log("🎉 Ready to test your free local AI coding assistant!");
