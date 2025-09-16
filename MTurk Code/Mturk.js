const fs = require("fs");
const xlsx = require('xlsx');

const sessionDataPath = "./formatted_sessions.json";
const commentDataPath = "./formatted_comments.json";
const userColorMapPath = "./formatted_map.json"; 

const paymentPerComment = 0.042;
const sessions = JSON.parse(fs.readFileSync(sessionDataPath, "utf8"));
const comments = JSON.parse(fs.readFileSync(commentDataPath, "utf8"));
const userColorMap = JSON.parse(fs.readFileSync(userColorMapPath, "utf8")); 
const sessionData = [];


function formatCommentID(index) {
  return (index + 1).toString().padStart(3, "0");
}

function colorUsername(username, userColorMap) {
  const color = userColorMap[username] || "grey";
  return `<span style="color: ${color};">@${username}</span>`;
}

function colorUserMentions(commentText, userColorMap) {
  const mentionRegex = /@\w+/g;
  return commentText.replace(mentionRegex, (match) => {
    const userName = match.substring(1); 
    return colorUsername(userName, userColorMap);
  });
}

sessions.forEach(session => {
  let associatedComments = comments.filter(comment => comment.unit_id === session.unit_id);
  let totalPaymentForSession = associatedComments.length * paymentPerComment;

  console.log(`Total payment for session ${session.unit_id}: $${totalPaymentForSession.toFixed(2)}`);
});

function generateSurveyForComment(comment, index) {
  const actualCommentID = comment.comment_id;
  const commenterContent = `${colorUsername(comment.anonymized_writer, userColorMap)}: ${colorUserMentions(comment.anonymized_comment || "", userColorMap)}`;

  return `
  <div class="comment">
    <h3>${commenterContent}</h3>
    <div class="question-container" id="question1_${actualCommentID}" style="margin-bottom: 0px; padding: 5px;">
      <div class="question">
        <label for="Cyberbullying_${actualCommentID}">Is there cyberbullying (even if in defense of the victim)?</label>
        <select id="Cyberbullying_${actualCommentID}" name="Cyberbullying_${actualCommentID}" onChange="toggleQuestions(this.value, '${actualCommentID}')">
          <option value="">Select an option</option>
          <option value="1">Yes</option>
          <option value="0">No</option>
        </select>
      </div>
    </div>

<div class="question-container" id="question2_${actualCommentID}" style="margin-bottom: 0px; padding: 5px; display: none;">      <div class="question">
        <label for="severityOfCyberbullying_${actualCommentID}">What is the severity?</label>
        <select id="severityOfCyberbullying_${actualCommentID}" name="severityOfCyberbullying_${actualCommentID}">
          <option value="">Select an option</option>
          <option value="mild">Mild</option>
          <option value="moderate">Moderate</option>
          <option value="severe">Severe</option>
        </select>
      </div>
    </div>

<div class="selected-options-container" id="selectedOptionsContainer_${actualCommentID}" style="display: none;">      <div class="question-container" id="question3_${actualCommentID}">
        <div class="question">
          <label for="topic_${actualCommentID}">What is the topic?</label>
          <button type="button" onclick="toggleDropdown('dropdown_${actualCommentID}')" aria-label="Select topic(s) of cyberbullying">Select option(s)</button>
        </div>
        <div id="dropdown_${actualCommentID}" class="checkbox-dropdown" style="display: none; position: absolute; background-color: #f9f9f9; border: 1px solid #ccc; padding: 10px; border-radius: 5px; width: calc(100% - 20px); box-shadow: 0 2px 5px rgba(0, 0, 0, 0.2);">
          <div class="checkbox-option">
            <input type="checkbox" id="sexual_${actualCommentID}" name="topicOfCyberbullying_${actualCommentID}[]" value="sexual" onchange="updateSelections('sexual', '${actualCommentID}')">
            <label for="sexualharrasment_${actualCommentID}">Sexual but not Gender Identity</label>
          </div>
          <div class="checkbox-option">
            <input type="checkbox" id="physical_${actualCommentID}" name="topicOfCyberbullying_${actualCommentID}[]" value="physical" onchange="updateSelections('physical', '${actualCommentID}')">
            <label for="physical_${actualCommentID}">Physical Appearance</label>
          </div>
          <div class="checkbox-option">
            <input type="checkbox" id="gender_${actualCommentID}" name="topicOfCyberbullying_${actualCommentID}[]" value="gender" onchange="updateSelections('gender', '${actualCommentID}')">
            <label for="genderidentity_${actualCommentID}">Gender Identity and Sexual Orientation</label>
          </div>
          <div class="checkbox-option">
            <input type="checkbox" id="disability_${actualCommentID}" name="topicOfCyberbullying_${actualCommentID}[]" value="disability" onchange="updateSelections('disability', '${actualCommentID}')">
            <label for="disability_${actualCommentID}">Disability and Neurodiversity</label>
          </div>
          <div class="checkbox-option">
            <input type="checkbox" id="social_status_${actualCommentID}" name="topicOfCyberbullying_${actualCommentID}[]" value="social_status" onchange="updateSelections('social_status', '${actualCommentID}')">
            <label for="social_status_${actualCommentID}">Social Status/Popularity</label>
          </div>
          <div class="checkbox-option">
            <input type="checkbox" id="race_${actualCommentID}" name="topicOfCyberbullying_${actualCommentID}[]" value="race" onchange="updateSelections('race', '${actualCommentID}')">
            <label for="race_${actualCommentID}">Race and Ethnicity</label>
          </div>
          <div class="checkbox-option">
            <input type="checkbox" id="intellectual_${actualCommentID}" name="topicOfCyberbullying_${actualCommentID}[]" value="intellectual" onchange="updateSelections('intellectual', '${actualCommentID}')">
            <label for="intellectual_${actualCommentID}">Intellectual and Academic</label>
          </div>
          <div class="checkbox-option">
            <input type="checkbox" id="religious_${actualCommentID}" name="topicOfCyberbullying_${actualCommentID}[]" value="religious" onchange="updateSelections('religious', '${actualCommentID}')">
            <label for="religious_${actualCommentID}">Religious</label>
          </div>
          <div class="checkbox-option">
            <input type="checkbox" id="political_${actualCommentID}" name="topicOfCyberbullying_${actualCommentID}[]" value="political" onchange="updateSelections('political', '${actualCommentID}')">
            <label for="political_${actualCommentID}">Political</label>
          </div>
          <div class="checkbox-option">
            <input type="checkbox" id="none_${actualCommentID}" name="topicOfCyberbullying_${actualCommentID}[]" value="none" onchange="updateSelections('none', '${actualCommentID}')">
            <label for="none_${actualCommentID}">Other</label>
          </div>
        </div>
      </div>
    </div>
<div class="question-container" id="question4_${actualCommentID}" style="margin-bottom: 0px; padding: 5px; display: none;">      <div class="question" style="display: flex; justify-content: space-between; align-items: center;">
        <div style="flex: 1; margin-right: 10px;">
          <label for="commentWriterRole_${actualCommentID}">What is the role of ${colorUsername(comment.anonymized_writer, userColorMap)} in this comment?</label>
          <select id="commentWriterRole_${actualCommentID}" name="commentWriterRole_${actualCommentID}" onChange="updateQuestion4Options(this.value, '${actualCommentID}')">
            <option value="">Select an option</option>
          </select>
        </div>
        <div id="severityContainer_${actualCommentID}" style="flex: 1; display:none;">
          <label id="severityLabel_${actualCommentID}" for="severityOfRole_${actualCommentID}">How is the victim being defended?</label>
          <select id="severityOfRole_${actualCommentID}" name="severityOfRole_${actualCommentID}">
          </select>
        </div>
      </div>
    </div>
  </div>
`;
}
sessions
  .forEach((session) => {
    let associatedComments = comments
      .filter((comment) => comment.unit_id === session.unit_id)
      .sort(
        (a, b) =>
          new Date(a.comment_created_at) - new Date(b.comment_created_at),
      );

    let totalPaymentForSession = associatedComments.length * paymentPerComment;

    let commentsSurveysHtml = associatedComments
      .map((comment, index) => generateSurveyForComment(comment, index))
      .join("");

    commentsSurveysHtml += `
      <div class="overall-question-container" style="margin-top: 20px; padding: 10px; border: 1px solid #ddd; border-radius: 5px; background-color: #f9f9f9;">
        <h3>Overall Session Bullying Assessment</h3>
        <div class="question">
          <label for="overallCyberbullying_${session.unit_id}">Who is the main victim in this post?</label>
          <select id="target_${session.unit_id}" name="target_${session.unit_id}">
            <option value="">Select an option</option>
            <option value="user">The user who created the post</option>
            <option value="participants">Participants in the comments</option>
            <option value="people_in_picture">People depicted in the picture</option>
            <option value="other">Other</option>
          </select>
        </div>
      </div>
    `;

    const mediaPath = 
    session.media_id 
    ? `../found_pictures/${session.media_id}.jpg`
    : "default.jpg";

    const ownerCommentContent = (session.anonymized_owner_comment && session.anonymized_owner_comment.trim() !== "")
    ? `${colorUsername(session.anonymized_owner_id, userColorMap)}: ${session.anonymized_owner_comment}`
    : `${colorUsername(session.anonymized_owner_id, userColorMap)}: [no text was provided by the user of the original post]`;

    const sessionHtmlContent = `
    <HTMLQuestion xmlns="http://mechanicalturk.amazonaws.com/AWSMechanicalTurkDataSchemas/2011-11-11/HTMLQuestion.xsd">
  <HTMLContent><![CDATA[
    <!DOCTYPE html>
    <html lang="en">
    <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>MTurk Task</title>
            <style>

            * {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body, html {
  width: 100%;
  font-family: Arial, Helvetica, sans-serif !important;
  min-height: 100%;
  background-color: #f9f9f9;
}

.modal {
  display: none;
  position: fixed;
  z-index: 1000;
  left: 0;
  top: 0;
  width: 100%;
  height: 100%;
  overflow: auto;
  background-color: rgb(0,0,0);
  background-color: rgba(0,0,0,0.9);
}

.modal-content {
  margin: auto;
  display: block;
  max-width: 50%;
}

.invalid-question-container {
  border: 2px solid red;
}

.modal-close {
  position: absolute;
  top: 15px;
  right: 35px;
  color: #f1f1f1;
  font-size: 40px;
  font-weight: bold;
  transition: 0.3s;
}

.modal-close:hover,
.modal-close:focus {
  color: #bbb;
  text-decoration: none;
  cursor: pointer;
}

#fixed-post {
  background-color: white;
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-weight: bold;
}

#fixed-post .post-text,
#fixed-post img {
  flex-basis: 50%;
}

#fixed-post img {
  max-width: 100%;
  object-fit: cover;
}

.comment {
  margin-top: 5px;
  padding: 2px;
  background-color: #fff;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
}

.question-container {
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  padding: 10px;
  background-color: #fff;
}

.question {
  display: flex;
  align-items: center;
  margin-bottom: 10px;
}

.question label {
  margin-right: 10px;
}

.question button,
.question select {
  padding: 8px;
  background-color: white;
  color: black;
  border: 1px solid #ccc;
  cursor: pointer;
  border-radius: 4px;
  box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.24), 0 0 2px 0 rgba(0, 0, 0, 0.12);
}

.question button:hover {
  background-color: #45a049;
}

.checkbox-dropdown {
  display: none;
  position: absolute;
  background-color: #fff;
  border: 1px solid #ccc;
  padding: 10px;
  border-radius: 5px;
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.2);
  width: calc(100% - 20px);
  z-index: 100;
}

.checkbox-option {
  display: flex;
  align-items: center;
  margin-bottom: 2px;
}

.checkbox-option label {
  margin-left: 5px;
  user-select: none;
}

.selected-options-container {
  display: flex;
  flex-wrap: wrap;
  gap: 5px;
  padding: 0px;
}

.instructions {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  background-color: #f9f9f9;
  z-index: 1000;
  padding: 10px;
  margin-bottom: 20px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.instructions h1 {
  font-size: 24px;
  margin-bottom: 10px;
}

.instructions .toggle-button {
  width: 20%;
  background-color: #4CAF50;
  color: white;
  padding: 10px 20px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 16px;
  margin-bottom: 10px;
}

.instructions .toggle-button:hover {
  background-color: #45a049;
}

.instructions .content {
  display: none;
  background-color: white;
  border-radius: 5px;
  padding: 15px;
}

.instructions .content.show {
  display: block;
  max-height: calc(100vh - 150px);
  overflow-y: auto;
}

.instructions ol {
  margin-left: 20px;
}

.instructions ul {
  margin-left: 30px;
}

.instructions li {
  margin-bottom: 5px;
}

.box {
  border: 1px solid #ccc;
  padding: 20px;
  margin-bottom: 20px;
  background-color: #f9f9f9;
}

.selected-options {
  display: flex;
  flex-wrap: wrap;
  gap: 5px;
}

.selected-options span {
  padding: 5px;
  background-color: #e0e0e0;
  border-radius: 5px;
}

.selected-options-container span {
  padding: 3px 5px;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #e0e0e0;
  border-radius: 5px;
  margin-bottom: 2px;
  font-size: 0.8em;
}

.instructio margin-bottom: 10px;
}

@media (max-height: 800px) {
  .instructions .content.show {
    max-height: 60vh;
  }
}

@media (max-height: 600px) {
  .instructions .content.show {
    max-height: 50vh;
  }
}

            </style>
            <script src="https://assets.crowd.aws/crowd-html-elements.js"></script>
            </head>
        <body>
        
        <div class="instructions">
  <button class="toggle-button">Hide Instructions</button>
  <div class="content box" >
    <h1>Annotator Instructions</h1>
    <p style = "color: blue;">Your tasks involves selecting if an Instagram comment has cyberbullying, the severity of cyberbullying, the topic of cyberbullying, and the role the user had in the bullying.</p>
    <hr>
    <br>

    <p  style = "color: blue;">
    Select the severity of the cyberbullying present in the comment.
    </p>
    <p><strong>Mild:</strong> Using mildly offensive language to attack or embarrass another person
                    <ul>
                        <li>Example: "You're an idiot, why would you do that?"</li>
                    </ul>
                </p>
                <p><strong>Moderate:</strong> Intense, offensive language which includes attacking personal beliefs or core values
                    <ul>
                        <li>Example: "I bet you voted Trump you stupid asshole"</li>
                    </ul>
                </p>
                <p><strong>Severe:</strong> Communicating physical threats, self-harm, blackmail, sexual assault, stalking, etc.
                    <ul>
                        <li>Example: "You should kill yourself before I find you and slash your throat in front of your kids"</li>
                    </ul>
                    </p>
    <hr>
    <br>
            <p style = "color: blue;">Select the cyberbullying topic being discussed in the comment. If none of these apply, then select Other.</p>
            <p><strong>Topics and Examples</strong></p>
            <ul>
                <li><strong>Sexual but not Gender Identity:</strong> "Girl I would do unspeakable things to you"</li>
                <li><strong>Gender Identity and Sexual Orientation:</strong> "Good job representing gay pride faggot"</li>
                <li><strong>Physical Appearance:</strong> "Wow I didn't know whales could wear bikinis!"</li>
                <li><strong>Disability and Neurodiversity:</strong> "Just stop being a depressed, anxious mess"</li>
                <li><strong>Social Status/Popularity:</strong> "Maybe you'd have friends if you weren't on welfare"</li>
                <li><strong>Race and Ethnicity:</strong> "Another lazy piece of shit wet back"</li>
                <li><strong>Intellectual and Academic:</strong> "How did you get past the 4th grade, dumb ass"</li>
                <li><strong>Religious:</strong> "Jesus sentenced nations to be destroyed and beat people"</li>
                <li><strong>Political:</strong> "You love the US? its a 2 party shithole"</li>
                <li><strong>Other:</strong> "Stop being yourself. Nobody wants that."</li>
            </ul>            
            <hr>
            <br>
            <p style = "color: blue;">Select the role that best describes the person who wrote this comment.</p>
            <ul>
                <p><strong>Passive Bystander:</strong> This person has not seen any bullying or if they saw any bullying related comments, they ignored them.
                    <ul>
                        <li>Example: "That looks awesome! I wish I was there!"</li>
                    </ul>
                </p>
                <p><strong>Bully:</strong> Someone who attacks, harasses, humiliates or threatens other people in the Instagram post.
                    <ul>
                        <li>Example: "Another example of Stephanine making an ass out of herself again."</li>
                    </ul>
                </p>
                <p><strong>Bully Assistant:</strong> Someone who sees bullying and begins to attack others in the comments.
                    <ul>
                        <li>Example: "What can you expect? Stephanine's dad never came back with the milk."</li>
                    </ul>
                </p>
                <p><strong>Aggressive Victim:</strong> A person being attacked who responds aggressively to their attacker.
                    <ul>
                        <li>Example: "Guys go fuck yourselves. You're just jealous that you weren't there."</li>
                    </ul>
                </p>
                <p><strong>Aggressive Defender of Victim:</strong> A person who attempts to help someone being attacked, but they respond aggressively towards the attacker.
                    <ul>
                        <li>Example: "Are you guys retarded? At least Stephanie goes out. GET SOME FRIENDS"</li>
                    </ul>
                </p>
                <p><strong>Non-Aggressive Victim:</strong> A person being attacked who either ignores the attack or responds non-aggressively to it.
                    <ul>
                        <li>Example: "Leave me alone, man. I'm sorry if that bothers you."</li>
                    </ul>
                </p>
                <p><strong>Non-Aggressive Defender of Victim:</strong> A person who attempts to help someone being attacked through non-aggressive support
                </ul>
                <hr>
                <p style = "color: blue;">
                If you selected Non-Aggressive Defender of Victim, select the type of support they are providing.
                </p>
                <ul>
                        <p><strong>Direct:</strong> Defender is communicating directly to the attacker to tell them what they did is wrong.
                            <ul>
                                <li>Example: "Do you realize how problematic what you just said is?"</li>
                            </ul>
                        </li>
                        <p><strong>Support:</strong> Defender is providing empathy and support to the person(s) being attacked
                            <ul>
                                <li>Example: "I'm here for you and I've got your back."</li>
                            </ul>
                        </li>
                    </ul>
                </li>
            </ul>
        </p>
  </div>
</div>

<crowd-form onsubmit="return validateForm()">
                <div id="fixed-post">
                  <div class="post-text">
                  <strong>
                    <p>${ownerCommentContent}</p>
                    <strong>
                  </div>
                  <a id="imgModalOpener"><img src="../found_pictures/${mediaPath}" alt="Post Image" style="width:100%;max-width:300px"></a>
                  </div>
                  <div id="myModal" class="modal">
  <span class="modal-close">&times;</span>
  <img class="modal-content" id="img01">
</div>
                ${commentsSurveysHtml}
            </crowd-form>
        
      <script>
      
      
      function markQuestionAsInvalid(questionContainer) {
        questionContainer.classList.add('invalid-question-container');
      }
      
      function markQuestionAsValid(questionContainer) {
        questionContainer.classList.remove('invalid-question-container');
      }

      const toggleButton = document.querySelector('.toggle-button');
const content = document.querySelector('.content');

// Add this line to show the content by default
content.classList.add('show');

toggleButton.addEventListener('click', () => {
  content.classList.toggle('show');
  if (content.classList.contains('show')) {
    toggleButton.textContent = 'Hide Instructions';
  } else {
    toggleButton.textContent = 'Show Instructions';
  }
});

  function toggleDropdown(id) {
    var dropdown = document.getElementById(id);
    var display = dropdown.style.display;
    dropdown.style.display = display === "none" ? "block" : "none";

    if (dropdown.style.display === "block") {
      setTimeout(() => {
        document.addEventListener("click", function handler(event) {
          if (
            !dropdown.contains(event.target) &&
            !event.target.matches("button")
          ) {
            dropdown.style.display = "none";
            document.removeEventListener("click", handler);
          }
        });
      }, 0);
    }
  }

  var coll = document.querySelector(".collapsible");
  coll.addEventListener("click", function() {
    this.classList.toggle("active");
    var content = this.nextElementSibling;
    if (content.style.display === "block") {
      content.style.display = "none";
    } else {
      content.style.display = "block";
    }
  });

  var modal = document.getElementById("myModal");
  var img = document.getElementById("imgModalOpener");
  var modalImg = document.getElementById("img01");
  img.onclick = function () {
    modal.style.display = "block";
    modalImg.src = this.children[0].src;
  };

  var span = document.getElementsByClassName("modal-close")[0];
  span.onclick = function () {
    modal.style.display = "none";
  };

  window.onclick = function (event) {
    if (event.target == modal) {
      modal.style.display = "none";
    }
  };

  function updateSelections(value, actualCommentID) {
    var checkbox = document.getElementById(value + "_" + actualCommentID);
    var selectedContainer = document.getElementById(
      "selectedOptionsContainer_" + actualCommentID
    );

    if (checkbox.checked) {
      var span = document.createElement("span");
      span.textContent = checkbox.nextElementSibling.innerText;
      span.setAttribute("data-value", value);
      span.style.padding = "5px";
      span.style.borderRadius = "5px";
      span.style.display = "flex";
      span.style.alignItems = "center";
      span.onclick = function () {
        checkbox.checked = false;
        updateSelections(value, actualCommentID);
      };
      selectedContainer.appendChild(span);
    } else {
      var items = selectedContainer.querySelectorAll(
        'span[data-value="' + value + '"]'
      );
      items.forEach(function (item) {
        selectedContainer.removeChild(item);
      });
    }
  }

  function validateForm() {
  let isValid = true;
  const comments = document.querySelectorAll('.comment');

  comments.forEach(comment => {
    const commentId = comment.querySelector('select[id^="Cyberbullying_"]').id.split('_')[1];
    const cyberbullyingSelect = comment.querySelector('select[id="Cyberbullying_' + commentId + '"]');
    const severitySelect = comment.querySelector('select[id="severityOfCyberbullying_' + commentId + '"]');
    const topicContainer = comment.querySelector('div[id="question3_' + commentId + '"]');
    const roleSelect = comment.querySelector('select[id="commentWriterRole_' + commentId + '"]');
    const severityOfRoleSelect = comment.querySelector('select[id="severityOfRole_' + commentId + '"]');

    if (cyberbullyingSelect.value === "") {
      isValid = false;
      markQuestionAsInvalid(cyberbullyingSelect.closest('.question-container'));
    } else {
      markQuestionAsValid(cyberbullyingSelect.closest('.question-container'));
    }

    if (cyberbullyingSelect.value === "1") {
      if (severitySelect.value === "") {
        isValid = false;
        markQuestionAsInvalid(severitySelect.closest('.question-container'));
      } else {
        markQuestionAsValid(severitySelect.closest('.question-container'));
      }

      const selectedTopics = Array.from(topicContainer.querySelectorAll('input[type="checkbox"]:checked'))
        .map(cb => cb.value);
      
      if (selectedTopics.length === 0) {
        isValid = false;
        markQuestionAsInvalid(topicContainer);
      } else {
        markQuestionAsValid(topicContainer);
      }

      if (roleSelect.value === "") {
        isValid = false;
        markQuestionAsInvalid(roleSelect.closest('.question-container'));
      } else {
        markQuestionAsValid(roleSelect.closest('.question-container'));
      }
    } else {
      severitySelect.value = "";
      topicContainer.querySelectorAll('input[type="checkbox"]:checked').forEach(cb => {
        cb.checked = false;
      });
    }

    if (roleSelect.value === "non_aggressive_defender") {
      if (!severityOfRoleSelect.value) {
        isValid = false;
        markQuestionAsInvalid(severityOfRoleSelect.closest('.question-container'));
      } else {
        markQuestionAsValid(severityOfRoleSelect.closest('.question-container'));
      }
    }
  });

  const overallQuestion = document.querySelector('select[id^="target_"]');
  if (overallQuestion.value === "") {
    isValid = false;
    markQuestionAsInvalid(overallQuestion.closest('.question'));
  } else {
    markQuestionAsValid(overallQuestion.closest('.question'));
  }

  if (!isValid) {
    alert("Please fill all required fields before submitting.");
  }

  return isValid;
}

function toggleQuestions(value, commentID) {
  // Get all relevant elements
  const severityDiv = document.getElementById("question2_" + commentID);
  const selectedOptionsContainer = document.getElementById("selectedOptionsContainer_" + commentID);
  const topicDiv = document.getElementById("question3_" + commentID);
  const topicCheckboxes = topicDiv.querySelectorAll('input[type="checkbox"]');
  const roleSelect = document.getElementById("commentWriterRole_" + commentID);
  const severityContainer = document.getElementById("severityContainer_" + commentID);
  const severityOfRoleSelect = document.getElementById("severityOfRole_" + commentID);
  const question4Container = document.getElementById("question4_" + commentID);

  // If no value is selected, hide everything
  if (value === "") {
    severityDiv.style.display = "none";
    selectedOptionsContainer.style.display = "none";
    question4Container.style.display = "none";
    return;
  }

  // Show question 4 since a selection was made
  question4Container.style.display = "block";
  
  // Show/hide severity and topic sections based on Yes/No
  const displayStyle = value === "1" ? "block" : "none";
  severityDiv.style.display = displayStyle;
  topicDiv.style.display = displayStyle;
  selectedOptionsContainer.style.display = "flex";
  selectedOptionsContainer.style.flexWrap = "wrap";
  selectedOptionsContainer.style.gap = "5px";

  // If cyberbullying is No (value === "0")
  if (value === "0") {
    // Clear all topic checkboxes
    topicCheckboxes.forEach(checkbox => {
      checkbox.checked = false;
    });
    
    // Clear any selected options display
    const selectedSpans = selectedOptionsContainer.querySelectorAll('span');
    selectedSpans.forEach(span => span.remove());
  }

  // Update role options
  roleSelect.innerHTML = "";
  if (value === "1") {
    roleSelect.options[roleSelect.options.length] = new Option("Select an option", "");
    roleSelect.options[roleSelect.options.length] = new Option("Bully", "bully");
    roleSelect.options[roleSelect.options.length] = new Option("Bully Assistant", "bully_assistant");
    roleSelect.options[roleSelect.options.length] = new Option("Aggressive Victim", "aggressive_victim");
    roleSelect.options[roleSelect.options.length] = new Option("Aggressive Defender of Victim", "aggressive_defender");
    roleSelect.options[roleSelect.options.length] = new Option("Non-aggressive Defender of Victim", "non_aggressive_defender");
  } else {
    roleSelect.options[roleSelect.options.length] = new Option("Select an option", "");
    roleSelect.options[roleSelect.options.length] = new Option("Non-aggressive Victim", "non_aggressive_victim");
    roleSelect.options[roleSelect.options.length] = new Option("Passive Bystander", "passive_bystander");
  }

  // Reset severity of role
  severityOfRoleSelect.innerHTML = "";
  severityContainer.style.display = "none";
}
  
  function updateQuestion4Options(role, commentID) {
    const severityLabel = document.getElementById("severityLabel_" + commentID);
    const severityDropdown = document.getElementById(
      "severityOfRole_" + commentID
    );
    const severityContainer = document.getElementById(
      "severityContainer_" + commentID
    );
  
    severityDropdown.innerHTML = "";
  
    if (
      [
        "bully",
        "aggressive_victim",
        "bully_assistant",
        "aggressive_defender",
      ].includes(role)
    ) {
      severityLabel.textContent = "Severity of the role?";
      severityContainer.style.display = "none"; 
    } else if (role === "non_aggressive_defender") {
      severityLabel.textContent = "How is the victim being defended?";
      severityDropdown.options[severityDropdown.options.length] = new Option(
        "Select an option",
        "",
        false,
        false
      );
      severityDropdown.options[severityDropdown.options.length] = new Option(
        "Confronting a bully",
        "direct_to_the_bully"
      );
      severityDropdown.options[severityDropdown.options.length] = new Option(
        "Supporting the victim",
        "support_of_the_victim"
      );
      severityContainer.style.display = "flex";
    } else {
      severityContainer.style.display = "none";
    }
  }

document.addEventListener('DOMContentLoaded', function() {
  setupEventListeners();
});      </script>
                </html>
              ]]></HTMLContent>
              <FrameHeight></FrameHeight>
            </HTMLQuestion>
    `;

    fs.writeFileSync(
      `./HTML/htmlForSession_${session.unit_id}.html`,
      sessionHtmlContent,
      "utf8",
    );
  });
  String.prototype.hashCode = function() {
    var hash = 0, i, chr;
    if (this.length === 0) return hash;
    for (i = 0; i < this.length; i++) {
      chr = this.charCodeAt(i);
      hash = ((hash << 5) - hash) + chr;
      hash |= 0; // Convert to 32bit integer
    }
    return Math.abs(hash).toString().substring(0, 6);
  };
  
  sessions.forEach(session => {
    let associatedComments = comments.filter(comment => comment.unit_id === session.unit_id);
    let totalPaymentForSession = associatedComments.length * paymentPerComment;
    const htmlFileName = `htmlForSession_${session.unit_id}.html`;
    const url = `https://raw.githack.com/arslanbisharat/mturk/main/HTML/${htmlFileName}`;
   
    sessionData.push({
        'Session ID': session.unit_id,
        'Post Owner Name': session.owner_id || "Unknown",
        'Anonymized Owner Name': session.anonymized_owner_id || "Unknown",
        'Number of Comments': associatedComments.length,
        'Media ID': session.media_id || "N/A",
        'Total Price': totalPaymentForSession.toFixed(2), 
        'URL': url
    });
});

  
  const workbook = xlsx.utils.book_new();
  const worksheet = xlsx.utils.json_to_sheet(sessionData);
  xlsx.utils.book_append_sheet(workbook, worksheet, 'Session Details');
  xlsx.writeFile(workbook, 'session_details.xlsx');
  
  console.log("Excel sheet 'session_details.xlsx' has been created successfully.");