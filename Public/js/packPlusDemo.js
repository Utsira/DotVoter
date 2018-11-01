// const dataset = [{
//     "message": "synthesize value-added action-items",
//     "voteCount": 9,
//     "category": "glad"
//   }, {
//     "message": "harness scalable deliverables",
//     "voteCount": 4,
//     "category": "glad"
//   }, {
//     "message": "embrace innovative e-tailers",
//     "voteCount": 8,
//     "category": "glad"
//   }, {
//     "message": "incubate ubiquitous synergies",
//     "voteCount": 5,
//     "category": "glad"
//   }, {
//     "message": "iterate bricks-and-clicks mindshare",
//     "voteCount": 7,
//     "category": "glad"
//   }, {
//     "message": "drive cross-platform e-services",
//     "voteCount": 2,
//     "category": "glad"
//   }, {
//     "message": "engage bricks-and-clicks e-commerce",
//     "voteCount": 6,
//     "category": "mad"
//   }, {
//     "message": "generate seamless eyeballs",
//     "voteCount": 2,
//     "category": "glad"
//   }, {
//     "message": "visualize clicks-and-mortar web-readiness",
//     "voteCount": 7,
//     "category": "mad"
//   }, {
//     "message": "reintermediate seamless functionalities",
//     "voteCount": 7,
//     "category": "sad"
//   }, {
//     "message": "grow value-added e-tailers",
//     "voteCount": 5,
//     "category": "sad"
//   }, {
//     "message": "optimize virtual interfaces",
//     "voteCount": 2,
//     "category": "sad"
//   }, {
//     "message": "implement B2B mindshare",
//     "voteCount": 5,
//     "category": "glad"
//   }, {
//     "message": "synergize e-business action-items",
//     "voteCount": 6,
//     "category": "mad"
//   }, {
//     "message": "integrate global e-tailers",
//     "voteCount": 6,
//     "category": "glad"
//   }, {
//     "message": "maximize cross-platform e-tailers",
//     "voteCount": 4,
//     "category": "glad"
//   }, {
//     "message": "recontextualize sticky deliverables",
//     "voteCount": 5,
//     "category": "sad"
//   }, {
//     "message": "reinvent revolutionary metrics",
//     "voteCount": 4,
//     "category": "glad"
//   }, {
//     "message": "maximize dot-com e-services",
//     "voteCount": 7,
//     "category": "glad"
//   }, {
//     "message": "seize open-source web services",
//     "voteCount": 6,
//     "category": "mad"
//   }];
/*
(point) => {
    return 1 + point.voteCount;
  }
*/

let visualization;

function setupViz(dataset) {
  visualization = d3plus.viz()
    .container("#viz")
    .data(dataset)
    .type("bubbles")
    .id(["category", "id"])
    .depth(1)
    .size("voteCount")
  //  .size({"value": "VoteCount"})//, "scale": {"min": 1}})
    .text({"category": "category","id": "message"})
    .color("message")
    // .width(window.innerWidth)
     .legend(false)
    .mouse({
      "click": (point, viz) => {
        upVote(point.id);
      }
    })
    .draw();
}

function upVote(id) {
  const payload = {
    action: "upVote",
    card: { voteCount: 0, id: id, message: "", category: "" }
  };
  socket.send(JSON.stringify(payload));
}

function newCard(message) {
  const payload = {
    action: "new",
    card: { voteCount: 0, message: message, category: "" }
  };
  socket.send(JSON.stringify(payload));
}

function setupForm() {
  const form = document.getElementById("newCard");
  form.addEventListener("submit", ev => {
    const message = ev.srcElement.elements.message.value;
    ev.srcElement.elements.message.value = "";
    ev.preventDefault();
    if (message.trim() == "") {
      return;
    }
    newCard(message)
    return;
  });
}

window.addEventListener('resize', () => {
  visualization.width(window.innerWidth)
    .draw()
});

const socket = new WebSocket("ws://localhost:8080/dotVote");

socket.addEventListener("message", ev => {
  const reader = new FileReader();
  reader.addEventListener("loadend", (ev) => {
    const text = ev.srcElement.result;
    const json = JSON.parse(text);
    if (visualization == null) {
      setupViz(json);
    } else {
      visualization.data(json)
        .draw();
    }
  });
  reader.readAsText(ev.data);
});

setupForm();

