/** @typedef {"loading" | "loaded"} AppStatus */
/**
 * @typedef {object} AudioMetadata
 * @property {string} filename
 * @property {string | undefined} character
 * @property {string | undefined} transcription
 * @property {number | undefined} isDistorted
 */

/**
 * @template T
 */
class RunSequence {
  /** @type {T[]} */
  sequence;
  /** @typedef {function(T, T): boolean} Comparator */
  /** @type {Comparator} */
  comparator;
  /** @type {number[]} */
  runs;

  /**
   * @param {Comparator} comparator A function that returns true if two values
   * should be in the same run.
   * @param {T[]} [[]] initialValues
   */
  constructor(comparator, initialValues = /** @type {T[]} */([])) {
    this.sequence = [];
    this.comparator = comparator;
    this.runs = [];
    this.extend(initialValues);
  }

  /**
   * @param {T} value A value to append to the sequence.
   */
  append(value) {
    // There are no runs when empty, so unconditionally create one if this is
    // the first value.
    if (this.sequence.length === 0) {
      this.runs.push(0);
      this.sequence.push(value);
      return;
    }
    // Create a new run if the value doesn't belong to the last run.
    if (!this.comparator(this.sequence[this.runs[this.runs.length - 1]], value)) {
      this.runs.push(this.sequence.length);
    }
    this.sequence.push(value);
  }

  /**
   * @param {T[]} values Values to add to the sequence.
   */
  extend(values) {
    values.forEach((value) => this.append(value));
  }

  /**
   * @returns {T[][]} An array of runs, each of which is the values in the run
   * in order.
   */
  getRuns() {
    return this.getRunRanges().map(([start, end]) => this.sequence.slice(start, end));
  }

  getRunRanges() {
    if (this.sequence.length === 0) {
      return [];
    }
    return this.runs.map((start, i) =>
      i === this.runs.length - 1 ?
        [start, this.sequence.length] :
        [start, this.runs[i + 1]]);
  }

  /**
   * @param {number} index The index of the element to get.
   * @returns {T} The element at the given index.
   */
  get(index) {
    return this.sequence[index];
  }

  /**
   * @param {number} index The index of the element to replace.
   * @param {T} value The value to place at that index.
   */
  set(index, value) {
    if (this.sequence.length === 0) {
      // No space to set data.
      return;
    }
    this.sequence[index] = value;
    if (this.sequence.length === 1) {
      // There's only one run possible and it already exists.
      return;
    }
    this.runs = this.sequence.reduce((runs, v, i) =>
      this.comparator(this.sequence[runs[runs.length - 1]], v) ?
        runs :
        [...runs, i], [0]);
  }

  /**
   * @param {number} index The index to get the containing range of indexes for.
   * @returns {[number, number]} The [start, end) range containing the index.
   */
  getIndexRange(index) {
    return this.getRunRanges().find(([start, end]) =>
      start <= index && index < end);
  }

  /**
   * @param {T} value A value that will be compared with a representative value
   * from each run using the comparator saved in the constructor.
   * @returns {[number, number][]} An array of all [start, end) ranges that
   * match the provided value.
   */
  getRangesMatching(value) {
    return this.getRunRanges().filter(([start,]) =>
      this.comparator(this.sequence[start], value));
  }
}

/**
 * @typedef {object} AppState
 * @property {AppStatus} overallStatus
 * @property {number} currentFileIndex
 * @property {RunSequence<AudioMetadata>} labeledAudioPartitioner
 */
/** @type {AppState} */
const state = {
  overallStatus: "loading",
  currentFileIndex: 0,
  labeledAudioPartitioner: new RunSequence(() => true),
};

const appRoot = document.getElementById("root");
appRoot.textContent = state.overallStatus;

const rawAudioMetadata = await fetchAllAudioMetadata();
state.overallStatus = "loaded";
appRoot.textContent = state.overallStatus;
state.labeledAudioPartitioner = new RunSequence((a, b) => isUnlabeled(a) === isUnlabeled(b), rawAudioMetadata)
const unlabeled = state.labeledAudioPartitioner.getRangesMatching({}).reduce((total, [start, end]) => total + end - start, 0);
console.log(`${rawAudioMetadata.length - unlabeled}/${rawAudioMetadata.length} labeled`);
console.log(state.labeledAudioPartitioner.getRuns());
state.currentFileIndex = selectRandomUnlabeledFileIndex(state.labeledAudioPartitioner);
renderLabeler(appRoot, { ...state, onSubmit: onLabel });

/**
 * @function
 * @returns {Promise<AudioMetadata[]>} All metadata from the server
 */
async function fetchAllAudioMetadata() {
  const response = await fetch("/api/audio");
  return await response.json();
}

async function getAudioMetadata(filename) {
  const response = await fetch(`/api${filename}`);
  return await response.json();
}

/**
 * 
 * @param {AudioMetadata} metadata The metadata to update
 * @returns {Promise<AudioMetadata>}
 */
async function saveAudioMetadata(metadata) {
  const response = await fetch(`/api${metadata.filename}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(metadata),
  });
  return await response.json();
}

async function onLabel(character, transcription, isDistorted) {
  const savedMetadata = await saveAudioMetadata({
    ...state.labeledAudioPartitioner.get(state.currentFileIndex),
    character,
    transcription,
    isDistorted: isDistorted ? 1 : 0,
  });
  state.labeledAudioPartitioner.set(state.currentFileIndex, savedMetadata);
  const nextIndex = nextUnlabeledFileIndex(state.labeledAudioPartitioner, state.currentFileIndex);
  if (nextIndex === undefined) {
    appRoot.textContent = "You finished everything! Wahoo!";
    return;
  }
  state.currentFileIndex = nextIndex;
  const nextMetadata = await getAudioMetadata(state.labeledAudioPartitioner.get(nextIndex).filename);
  if (isUnlabeled(nextMetadata)) {
    renderLabeler(appRoot, { ...state, onSubmit: onLabel });
  } else {
    appRoot.textContent = "Labelling collision detected, refresh to start from a new file";
  }
}

/**
 * 
 * @param {AudioMetadata} audio 
 */
function isUnlabeled({ character, transcription, isDistorted }) {
  return character === undefined &&
    transcription === undefined &&
    isDistorted === undefined;
}

/**
 * @param {RunSequence<AudioMetadata>} runSequence The metadata to search through.
 * @returns {number} The index of a random unlabeled file.
 */
function selectRandomUnlabeledFileIndex(runSequence) {
  const unlabeledRuns = runSequence.getRangesMatching({ filename: "" });
  const counts = unlabeledRuns.map(([start, end]) => end - start);
  const total = counts.reduce((a, b) => a + b, 0);
  let randomIndex = Math.floor(total * Math.random());
  console.debug({ unlabeledRuns, total, randomIndex });
  let run = 0;
  for (run = 0; run < unlabeledRuns.length; ++run) {
    if (randomIndex < counts[run]) {
      return unlabeledRuns[run][0] + randomIndex;
    }
    randomIndex -= counts[run];
  }
}

/**
 * @param {RunSequence<AudioMetadata>} runSequence 
 * @param {number} index The index to start searching from.
 * @returns {number | undefined} The provided index if its unlabeled, the next
 * unlabeled index if it is labeled, accounting for wrapping past the end.
 * undefined if there is no unlabeled data.
 */
function nextUnlabeledFileIndex(runSequence, index) {
  const unlabeledRuns = runSequence.getRangesMatching({ filename: "" });
  if (unlabeledRuns.length === 0) {
    // Everything is labeled, wahoo!
    return;
  }
  const indexIsUnlabeled = unlabeledRuns.findIndex(([start, end]) => start <= index && index < end) !== -1;
  if (indexIsUnlabeled) {
    return index;
  }
  const nextUnlabeledRun = unlabeledRuns.find(([start,]) => index < start);
  if (nextUnlabeledRun !== undefined) {
    return nextUnlabeledRun[0];
  }
  // Wrap around to the beginning if we went past the end.
  return unlabeledRuns[0][0];
}

/**
 * 
 * @param {HTMLElement} containingElement The element to render into.
 * @param {object} props The required parameters to render.
 * @param {number} props.currentFileIndex
 * @param {RunSequence<AudioMetadata>} props.labeledAudioPartitioner
 * @param {function(string, string, boolean): Promise<void>} props.onSubmit
 */
function renderLabeler(containingElement, {
  currentFileIndex,
  labeledAudioPartitioner,
  onSubmit,
}) {
  const currentFile = labeledAudioPartitioner.get(currentFileIndex);

  const player = document.createElement("audio");
  player.src = currentFile.filename;
  player.controls = true;

  const characterInput = document.createElement("input");
  characterInput.type = "text";
  characterInput.id = "character";
  characterInput.placeholder = "Speaker";

  const isDistortedCheckbox = document.createElement("input");
  isDistortedCheckbox.type = "checkbox";
  isDistortedCheckbox.id = "is-distorted";
  const isDistortedLabel = document.createElement("label");
  isDistortedLabel.htmlFor = isDistortedCheckbox.id;
  isDistortedLabel.textContent = "Is distorted";

  const transcriptionInput = document.createElement("textarea");
  transcriptionInput.id = "transcription";
  transcriptionInput.placeholder = "Transcribe the audio";

  const submitButton = document.createElement("input");
  submitButton.type = "submit";
  submitButton.value = "Submit";

  const flexSpacer = document.createElement("div");
  flexSpacer.className = "flex-spacer";
  const bottomRow = document.createElement("div");
  bottomRow.classList = "bottom-row";
  bottomRow.appendChild(isDistortedCheckbox);
  bottomRow.appendChild(isDistortedLabel);
  bottomRow.appendChild(flexSpacer);
  bottomRow.appendChild(submitButton);

  const form = document.createElement("form");
  form.id = "add-transcription";
  form.addEventListener("submit", async (e) => {
    e.preventDefault();

    await onSubmit(
      characterInput.value,
      transcriptionInput.value,
      isDistortedCheckbox.checked
    );
  });
  form.appendChild(characterInput);
  form.appendChild(transcriptionInput);
  form.appendChild(bottomRow);

  const labeler = document.createElement("div");
  labeler.className = "labeler";
  labeler.appendChild(player);
  labeler.appendChild(form);

  while (containingElement.hasChildNodes()) {
    containingElement.removeChild(containingElement.firstChild);
  }
  containingElement.appendChild(labeler);
}
