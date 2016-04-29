//
//  StaffTests.swift
//  MusicNotationKit
//
//  Created by Kyle Sherman on 9/5/15.
//  Copyright © 2015 Kyle Sherman. All rights reserved.
//

import XCTest
@testable import MusicNotationKit

class StaffTests: XCTestCase {

	var staff: Staff!
	
    override func setUp() {
        super.setUp()
		staff = Staff(clef: .Treble, instrument: .Guitar6)
		let timeSignature = TimeSignature(topNumber: 4, bottomNumber: 4, tempo: 120)
		let key = Key(noteLetter: .C)
		let note = Note(noteDuration: .Sixteenth,
			tone: Tone(noteLetter: .C, octave: .Octave1))
		let tuplet = try! Tuplet(notes: [note, note, note])
		let measure1 = Measure(
			timeSignature: timeSignature,
			key: key,
			notes: [note, note, note, note, tuplet]
		)
		let measure2 = Measure(
			timeSignature: timeSignature,
			key: key,
			notes: [tuplet, note, note]
		)
		let measure3 = Measure(
			timeSignature: timeSignature,
			key: key,
			notes: [note, note, note, note, tuplet]
		)
		let measure4 = Measure(
			timeSignature: timeSignature,
			key: key,
			notes: [note, note, note, note]
		)
		let measure5 = Measure(
			timeSignature: timeSignature,
			key: key,
			notes: [tuplet, note, note, note, note]
		)
		let measure6 = Measure(
			timeSignature: timeSignature,
			key: key,
			notes: [tuplet, tuplet, note, note]
		)
		let repeat1 = try! MeasureRepeat(measures: [measure4])
		let repeat2 = try! MeasureRepeat(measures: [measure4, measure4], repeatCount: 2)
		staff.appendMeasure(measure1)
		staff.appendMeasure(measure2)
		staff.appendMeasure(measure3)
		staff.appendMeasure(measure4)
		staff.appendMeasure(measure5)
		staff.appendRepeat(repeat1) // index = 5
		staff.appendRepeat(repeat2) // index = 7
		staff.appendMeasure(measure6) // index = 13
    }

	// MARK: - startTieFromNoteAtIndex(_:, inMeasureAtIndex:)
	// MARK: Failures
	
	func testStartTieFailIfNoteIndexInvalid() {
		do {
			try staff.startTieFromNoteAtIndex(10, inMeasureAtIndex: 0)
			shouldFail()
		} catch StaffError.NoteIndexOutOfRange {
		} catch {
			expected(StaffError.NoteIndexOutOfRange, actual: error)
		}
	}
	
	func testStartTieFailIfMeasureIndexInvalid() {
		do {
			try staff.startTieFromNoteAtIndex(0, inMeasureAtIndex: 10)
			shouldFail()
		} catch StaffError.MeasureIndexOutOfRange {
		} catch {
			expected(StaffError.MeasureIndexOutOfRange, actual: error)
		}
	}
	
	func testStartTieFailIfNoNextNote() {
		do {
			try staff.startTieFromNoteAtIndex(3, inMeasureAtIndex: 2)
			shouldFail()
		} catch StaffError.NoNextNoteToTie {
		} catch {
			expected(StaffError.NoNextNoteToTie, actual: error)
		}
	}
	
	func testStartTieFailIfLastNoteOfTupletAndNoNextNote() {
		do {
			try staff.startTieFromNoteAtIndex(6, inMeasureAtIndex: 2)
			shouldFail()
		} catch StaffError.NoNextNoteToTie {
		} catch {
			expected(StaffError.NoNextNoteToTie, actual: error)
		}
	}
	
	func testStartTieFailIfLastNoteOfSingleMeasureRepeat() {
		// Reason: can't finish in the next measure
		do {
			try staff.startTieFromNoteAtIndex(3, inMeasureAtIndex: 5)
			shouldFail()
		} catch StaffError.NoNextNoteToTie {
		} catch {
			expected(StaffError.NoNextNoteToTie, actual: error)
		}
	}
	
	func testStartTieFailIfLastNoteInLastMeasureOfMultiMeasureRepeat() {
		do {
			try staff.startTieFromNoteAtIndex(3, inMeasureAtIndex: 6)
			shouldFail()
		} catch StaffError.NoNextNoteToTie {
		} catch {
			expected(StaffError.NoNextNoteToTie, actual: error)
		}
	}
	
	func testStartTieFailIfNotesWithinRepeatAfterTheFirstCount() {
		do {
			try staff.startTieFromNoteAtIndex(0, inMeasureAtIndex: 8)
			shouldFail()
		} catch StaffError.RepeatedMeasureCannotHaveTie {
		} catch {
			expected(StaffError.RepeatedMeasureCannotHaveTie, actual: error)
		}
	}
	
	// MARK: Successes
	
	func testStartTieWithinMeasureIfHasNextNote() {
		do {
			let firstNoteIndex = 0
			let firstMeasureIndex = 0
			try staff.startTieFromNoteAtIndex(firstNoteIndex, inMeasureAtIndex: firstMeasureIndex)
			let measure = staff.notesHolders[firstMeasureIndex] as! Measure
			let firstNote = measure.notes[firstNoteIndex] as! Note
			let secondNote = measure.notes[firstNoteIndex + 1] as! Note
			XCTAssert(firstNote.tie == .Begin)
			XCTAssert(secondNote.tie == .End)
		} catch {
			XCTFail(String(error))
		}
	}
	
	func testStartTieWithinMeasureIfAlreadyEndOfTie() {
		do {
			let firstNoteIndex = 0
			let firstMeasureIndex = 0
			try staff.startTieFromNoteAtIndex(firstNoteIndex, inMeasureAtIndex: firstMeasureIndex)
			try staff.startTieFromNoteAtIndex(firstNoteIndex + 1, inMeasureAtIndex: firstMeasureIndex)
			let measure = staff.notesHolders[firstMeasureIndex] as! Measure
			let firstNote = measure.notes[firstNoteIndex] as! Note
			let secondNote = measure.notes[firstNoteIndex + 1] as! Note
			let thirdNote = measure.notes[firstNoteIndex + 2] as! Note
			XCTAssert(firstNote.tie == .Begin)
			XCTAssert(secondNote.tie == .BeginAndEnd)
			XCTAssert(thirdNote.tie == .End)
		} catch {
			XCTFail(String(error))
		}
	}
	
	func testStartTieWithinMeasureTupletToTuplet() {
		do {
			let firstNoteIndex = 2
			let firstMeasureIndex = 13
			try staff.startTieFromNoteAtIndex(firstNoteIndex, inMeasureAtIndex: firstMeasureIndex)
			let measure = staff.notesHolders[7] as! Measure
			let firstNote = (measure.notes[0] as! Tuplet).notes[2]
			let secondNote = (measure.notes[1] as! Tuplet).notes[0]
			XCTAssert(firstNote.tie == .Begin)
			XCTAssert(secondNote.tie == .End)
		} catch {
			XCTFail(String(error))
		}
	}
	
	func testStartTieAcrossMeasuresNoteToNote() {
		do {
			let firstNoteIndex = 4
			let firstMeasureIndex = 1
			try staff.startTieFromNoteAtIndex(firstNoteIndex, inMeasureAtIndex: firstMeasureIndex)
			let firstMeasure = staff.notesHolders[firstMeasureIndex] as! Measure
			let secondMeasure = staff.notesHolders[firstMeasureIndex + 1] as! Measure
			let firstNote = firstMeasure.notes[2] as! Note
			let secondNote = secondMeasure.notes[0] as! Note
			XCTAssert(firstNote.tie == .Begin)
			XCTAssert(secondNote.tie == .End)
		} catch {
			XCTFail(String(error))
		}
	}
	
	func testStartTieAcrossMeasuresNoteToTuplet() {
		do {
			let firstNoteIndex = 3
			let firstMeasureIndex = 3
			try staff.startTieFromNoteAtIndex(firstNoteIndex, inMeasureAtIndex: firstMeasureIndex)
			let firstMeasure = staff.notesHolders[firstMeasureIndex] as! Measure
			let secondMeasure = staff.notesHolders[firstMeasureIndex + 1] as! Measure
			let firstNote = firstMeasure.notes[3] as! Note
			let secondNote = (secondMeasure.notes[0] as! Tuplet).notes[0]
			XCTAssert(firstNote.tie == .Begin)
			XCTAssert(secondNote.tie == .End)
		} catch {
			XCTFail(String(error))
		}
	}
	
	func testStartTieAcrossMeasuresTupletToNote() {
		do {
			let firstNoteIndex = 6
			let firstMeasureIndex = 2
			try staff.startTieFromNoteAtIndex(firstNoteIndex, inMeasureAtIndex: firstMeasureIndex)
			let firstMeasure = staff.notesHolders[firstMeasureIndex] as! Measure
			let secondMeasure = staff.notesHolders[firstMeasureIndex + 1] as! Measure
			let firstNote = (firstMeasure.notes[4] as! Tuplet).notes[2]
			let secondNote = secondMeasure.notes[0] as! Note
			XCTAssert(firstNote.tie == .Begin)
			XCTAssert(secondNote.tie == .End)
		} catch {
			XCTFail(String(error))
		}
	}
	
	func testStartTieAcrossMeasuresTupletToTuplet() {
		do {
			let firstNoteIndex = 6
			let firstMeasureIndex = 0
			try staff.startTieFromNoteAtIndex(firstNoteIndex, inMeasureAtIndex: firstMeasureIndex)
			let firstMeasure = staff.notesHolders[firstMeasureIndex] as! Measure
			let secondMeasure = staff.notesHolders[firstMeasureIndex + 1] as! Measure
			let firstNote = (firstMeasure.notes[4] as! Tuplet).notes[2]
			let secondNote = (secondMeasure.notes[0] as! Tuplet).notes[0]
			XCTAssert(firstNote.tie == .Begin)
			XCTAssert(secondNote.tie == .End)
		} catch {
			XCTFail(String(error))
		}
	}
	
	func testStartTieBothNotesWithinSingleMeasureRepeat() {
		do {
			let firstNoteIndex = 0
			let firstMeasureIndex = 5
			try staff.startTieFromNoteAtIndex(firstNoteIndex, inMeasureAtIndex: firstMeasureIndex)
			let firstMeasure = (staff.notesHolders[firstMeasureIndex] as! MeasureRepeat).measures[0]
			let firstNote = firstMeasure.notes[firstNoteIndex] as! Note
			let secondNote = firstMeasure.notes[firstNoteIndex + 1] as! Note
			XCTAssert(firstNote.tie == .Begin)
			XCTAssert(secondNote.tie == .End)
		} catch {
			XCTFail(String(error))
		}
	}
	
	func testStartTieBothNotesWithinMultiMeasureRepeat() {
		do {
			let firstNoteIndex = 0
			let firstMeasureIndex = 7
			try staff.startTieFromNoteAtIndex(firstNoteIndex, inMeasureAtIndex: firstMeasureIndex)
			let firstMeasure = (staff.notesHolders[6] as! MeasureRepeat).measures[0]
			let firstNote = firstMeasure.notes[firstNoteIndex] as! Note
			let secondNote = firstMeasure.notes[firstNoteIndex + 1] as! Note
			XCTAssert(firstNote.tie == .Begin)
			XCTAssert(secondNote.tie == .End)
		} catch {
			XCTFail(String(error))
		}
	}
	
	func testStartTieNotesFromContiguousMeasuresWithinRepeat() {
		do {
			let firstNoteIndex = 3
			let firstMeasureIndex = 7
			try staff.startTieFromNoteAtIndex(firstNoteIndex, inMeasureAtIndex: firstMeasureIndex)
			let measureRepeat = staff.notesHolders[6] as! MeasureRepeat
			let firstMeasure = measureRepeat.measures[0]
			let secondMeasure = measureRepeat.measures[1]
			let firstNote = firstMeasure.notes[firstNoteIndex] as! Note
			let secondNote = secondMeasure.notes[0] as! Note
			XCTAssert(firstNote.tie == .Begin)
			XCTAssert(secondNote.tie == .End)
		} catch {
			XCTFail(String(error))
		}
	}
	
	// MARK: - removeTieFromNoteAtIndex(_:, inMeasureAtIndex:)
	// MARK: Failures
	
	func testRemoveTieFailIfNoteIndexInvalid() {
		do {
			try staff.removeTieFromNoteAtIndex(10, inMeasureAtIndex: 0)
			shouldFail()
		} catch StaffError.NoteIndexOutOfRange {
		} catch {
			expected(StaffError.NoteIndexOutOfRange, actual: error)
		}
	}
	
	func testRemoveTieFailIfMeasureIndexInvalid() {
		do {
			try staff.removeTieFromNoteAtIndex(0, inMeasureAtIndex: 10)
			shouldFail()
		} catch StaffError.MeasureIndexOutOfRange {
		} catch {
			expected(StaffError.MeasureIndexOutOfRange, actual: error)
		}
	}
	
	func testRemoveTieFailIfNotTied() {
		do {
			try staff.removeTieFromNoteAtIndex(0, inMeasureAtIndex: 0)
			shouldFail()
		} catch StaffError.NotBeginningOfTie {
		} catch {
			expected(StaffError.NotBeginningOfTie, actual: error)
		}
	}
	
	func testRemoveTieFailIfNotBeginningOfTie() {
		do {
			try staff.startTieFromNoteAtIndex(0, inMeasureAtIndex: 0)
			try staff.removeTieFromNoteAtIndex(1, inMeasureAtIndex: 0)
			shouldFail()
		} catch StaffError.NotBeginningOfTie {
		} catch {
			expected(StaffError.NotBeginningOfTie, actual: error)
		}
	}
	
	// MARK: Successes
	
	func testRemoveTieWithinMeasureNoteToNote() {
		do {
			let firstNoteIndex = 0
			let firstMeasureIndex = 0
			try staff.startTieFromNoteAtIndex(firstNoteIndex, inMeasureAtIndex: firstMeasureIndex)
			try staff.removeTieFromNoteAtIndex(firstNoteIndex, inMeasureAtIndex: firstMeasureIndex)
			let measure = staff.notesHolders[firstMeasureIndex] as! Measure
			let firstNote = measure.notes[firstNoteIndex] as! Note
			let secondNote = measure.notes[firstNoteIndex + 1] as! Note
			XCTAssertNil(firstNote.tie)
			XCTAssertNil(secondNote.tie)
		} catch {
			XCTFail(String(error))
		}
	}
	
	func testRemoveTieWithinMeasureWithinTuplet() {
		do {
			let firstNoteIndex = 4
			let firstMeasureIndex = 0
			try staff.startTieFromNoteAtIndex(firstNoteIndex, inMeasureAtIndex: firstMeasureIndex)
			try staff.removeTieFromNoteAtIndex(firstNoteIndex, inMeasureAtIndex: firstMeasureIndex)
			let measure = staff.notesHolders[firstMeasureIndex] as! Measure
			let firstNote = (measure.notes[firstNoteIndex] as! Tuplet).notes[0]
			let secondNote = (measure.notes[firstNoteIndex] as! Tuplet).notes[1]
			XCTAssertNil(firstNote.tie)
			XCTAssertNil(secondNote.tie)
		} catch {
			XCTFail(String(error))
		}
	}
	
	func testRemoveTieWithinMeasureFromTupletToNote() {
		do {
			let firstNoteIndex = 2
			let firstMeasureIndex = 1
			try staff.startTieFromNoteAtIndex(firstNoteIndex, inMeasureAtIndex: firstMeasureIndex)
			try staff.removeTieFromNoteAtIndex(firstNoteIndex, inMeasureAtIndex: firstMeasureIndex)
			let measure = staff.notesHolders[firstMeasureIndex] as! Measure
			let firstNote = (measure.notes[0] as! Tuplet).notes[firstNoteIndex]
			let secondNote = measure.notes[1] as! Note
			XCTAssertNil(firstNote.tie)
			XCTAssertNil(secondNote.tie)
		} catch {
			XCTFail(String(error))
		}
	}

	func testRemoveTieWithinMeasureFromTupletToNewTuplet() {
		do {
			let firstNoteIndex = 2
			let firstMeasureIndex = 11
			try staff.startTieFromNoteAtIndex(firstNoteIndex, inMeasureAtIndex: firstMeasureIndex)
			try staff.removeTieFromNoteAtIndex(firstNoteIndex, inMeasureAtIndex: firstMeasureIndex)
			let measure = staff.notesHolders[7] as! Measure
			let firstNote = (measure.notes[0] as! Tuplet).notes[firstNoteIndex]
			let secondNote = (measure.notes[1] as! Tuplet).notes[0]
			XCTAssertNil(firstNote.tie)
			XCTAssertNil(secondNote.tie)
		} catch {
			XCTFail(String(error))
		}
	}

	func testRemoveTieAcrossMeasuresFromTupletToNote() {
		do {
			let firstNoteIndex = 6
			let firstMeasureIndex = 2
			try staff.startTieFromNoteAtIndex(firstNoteIndex, inMeasureAtIndex: firstMeasureIndex)
			try staff.removeTieFromNoteAtIndex(firstNoteIndex, inMeasureAtIndex: firstMeasureIndex)
			let measure1 = staff.notesHolders[firstMeasureIndex] as! Measure
			let measure2 = staff.notesHolders[firstMeasureIndex + 1] as! Measure
            let firstNote = (measure1.notes[4] as! Tuplet).notes[2]
			let secondNote = measure2.notes[0] as! Note
			XCTAssertNil(firstNote.tie)
			XCTAssertNil(secondNote.tie)
		} catch {
			XCTFail(String(error))
		}
	}

	func testRemoveTieAcrosssMeasuresFromTupletToNewTuplet() {
		do {
			let firstNoteIndex = 6
			let firstMeasureIndex = 0
			try staff.startTieFromNoteAtIndex(firstNoteIndex, inMeasureAtIndex: firstMeasureIndex)
			try staff.removeTieFromNoteAtIndex(firstNoteIndex, inMeasureAtIndex: firstMeasureIndex + 1)
			let measure1 = staff.notesHolders[firstMeasureIndex] as! Measure
			let measure2 = staff.notesHolders[firstMeasureIndex + 1] as! Measure
			let firstNote = (measure1.notes[4] as! Tuplet).notes[2]
			let secondNote = (measure2.notes[0] as! Tuplet).notes[0]
			XCTAssertNil(firstNote.tie)
			XCTAssertNil(secondNote.tie)
		} catch {
			XCTFail(String(error))
		}
	}
	
	func testremoveTieFromNoteAtIndexThatIsBeginAndEnd() {
		do {
			let firstNoteIndex = 0
			let firstMeasureIndex = 0
			try staff.startTieFromNoteAtIndex(firstNoteIndex, inMeasureAtIndex: firstMeasureIndex)
			try staff.startTieFromNoteAtIndex(firstNoteIndex + 1, inMeasureAtIndex: firstMeasureIndex)
			try staff.removeTieFromNoteAtIndex(firstNoteIndex + 1, inMeasureAtIndex: firstMeasureIndex)
			let measure = staff.notesHolders[firstMeasureIndex] as! Measure
			let firstNote = measure.notes[firstNoteIndex] as! Note
			let secondNote = measure.notes[firstNoteIndex + 1] as! Note
			let thirdNote = measure.notes[firstNoteIndex + 2] as! Note
			XCTAssert(firstNote.tie == .Begin)
			XCTAssert(secondNote.tie == .End)
			XCTAssertNil(thirdNote.tie)
		} catch {
			XCTFail(String(error))
		}
	}
	
	// MARK: - notesHolderIndexFromMeasureIndex(_: Int) -> (Int, Int?)
	// MARK: Failures
	
	func testNotesHolderIndexForOutOfRangeMeasureIndex() {
		do {
			let _ = try staff.notesHolderIndexFromMeasureIndex(20)
			shouldFail()
		} catch StaffError.MeasureIndexOutOfRange {
		} catch {
			expected(StaffError.MeasureIndexOutOfRange, actual: error)
		}
	}
	
	// MARK: Successes
	
	func testNotesHolderIndexForNoRepeats() {
		do {
			let indexes = try staff.notesHolderIndexFromMeasureIndex(2)
			XCTAssertEqual(indexes.notesHolderIndex, 2)
			XCTAssertNil(indexes.repeatMeasureIndex)
		} catch {
			XCTFail(String(error))
		}
	}
	
	func testNotesHolderIndexForOriginalRepeatedMeasure() {
		do {
			let indexes = try staff.notesHolderIndexFromMeasureIndex(8)
			XCTAssertEqual(indexes.notesHolderIndex, 6)
			XCTAssertEqual(indexes.repeatMeasureIndex, 1)
		} catch {
			XCTFail(String(error))
		}
	}
	
	func testNotesHolderIndexForRepeatedMeasure() {
		do {
			let indexes = try staff.notesHolderIndexFromMeasureIndex(9)
			XCTAssertEqual(indexes.notesHolderIndex, 6)
			XCTAssertEqual(indexes.repeatMeasureIndex, 2)
		} catch {
			XCTFail(String(error))
		}
	}
	
	func testNotesHolderIndexForAfterRepeat() {
		do {
			let indexes = try staff.notesHolderIndexFromMeasureIndex(13)
			XCTAssertEqual(indexes.notesHolderIndex, 7)
			XCTAssertNil(indexes.repeatMeasureIndex)
		} catch {
			XCTFail(String(error))
		}
	}
	
	// MARK: - notesHolderAtIndex(_: Int) -> NotesHolder
	// MARK: Failures
	
	func testNotesHolderAtIndexForInvalidIndexNegative() {
		do {
			let _ = try staff.notesHolderAtIndex(-3)
			shouldFail()
		} catch StaffError.MeasureIndexOutOfRange {
		} catch {
			expected(StaffError.MeasureIndexOutOfRange, actual: error)
		}
	}
	
	func testNotesHolderAtIndexForInvalidIndexTooLarge() {
		do {
			let _ = try staff.notesHolderAtIndex(99)
			shouldFail()
		} catch StaffError.MeasureIndexOutOfRange {
		} catch {
			expected(StaffError.MeasureIndexOutOfRange, actual: error)
		}
	}
	
	// MARK: Successes
	
	func testNotesHolderAtIndexForFirstMeasureThatIsRepeated() {
		do {
			let actual = try staff.notesHolderAtIndex(5)
            let expected = staff.notesHolders[5]
            XCTAssertEqual(actual as? MeasureRepeat, expected as? MeasureRepeat)
		} catch {
			XCTFail(String(error))
		}
	}

    func testNotesHolderAtIndexForSecondMeasureThatIsRepeated() {
        do {
            let actual = try staff.notesHolderAtIndex(8)
            let expected = staff.notesHolders[7]
            XCTAssertEqual(actual as? MeasureRepeat, expected as? MeasureRepeat)
        } catch {
            XCTFail(String(error))
        }
    }

    func testNotesHolderAtIndexForRepeatedMeasureInFirstRepeat() {
        do {
            let actual = try staff.notesHolderAtIndex(6)
            let expected = staff.notesHolders[5]
            XCTAssertEqual(actual as? MeasureRepeat, expected as? MeasureRepeat)
        } catch {
            XCTFail(String(error))
        }
    }

    func testNotesHolderAtIndexForRepeatedMeasureInSecondRepeat() {
        do {
            let actual = try staff.notesHolderAtIndex(12)
            let expected = staff.notesHolders[7]
            XCTAssertEqual(actual as? MeasureRepeat, expected as? MeasureRepeat)
        } catch {
            XCTFail(String(error))
        }
    }
	
	func testNotesHolderAtIndexForRegularMeasure() {
		do {
			let actual = try staff.notesHolderAtIndex(0)
            let expected = staff.notesHolders[0]
			XCTAssertEqual(actual as? Measure, expected as? Measure)
		} catch {
			XCTFail(String(error))
		}
	}
	
	// MARK: - measureAtIndex(_: Int) -> ImmutableMeasure
	// MARK: Failures
	
	func testMeasureAtIndexForInvalidIndexNegative() {
		do {
			let _ = try staff.measureAtIndex(-1)
			shouldFail()
		} catch StaffError.MeasureIndexOutOfRange {
		} catch {
			expected(StaffError.MeasureIndexOutOfRange, actual: error)
		}
	}
	
	func testMeasureAtIndexForInvalidIndexTooLarge() {
		do {
			let _ = try staff.measureAtIndex(staff.notesHolders.count + 10)
			shouldFail()
		} catch StaffError.MeasureIndexOutOfRange {
		} catch {
			expected(StaffError.MeasureIndexOutOfRange, actual: error)
		}
	}
	
	// MARK: Successes
	
	func testMeasureAtIndexForRegularMeasure() {
		do {
			let measure = try staff.measureAtIndex(1)
			XCTAssertEqual(measure as? Measure, staff.notesHolders[1] as? Measure)
		} catch {
			XCTFail(String(error))
		}
	}
	
	func testMeasureAtIndexForMeasureThatRepeats() {
		do {
			let measureThatRepeats = try staff.measureAtIndex(5)
			let measureRepeat = staff.notesHolders[5] as! MeasureRepeat
			XCTAssertEqual(measureThatRepeats as? RepeatedMeasure, measureRepeat.expand()[0] as? RepeatedMeasure)
		} catch {
			XCTFail(String(error))
		}
	}
	
	func testMeasureAtIndexForRepeatedMeasure() {
		do {
			let repeatedMeasure = try staff.measureAtIndex(6)
			let measureRepeat = staff.notesHolders[5] as! MeasureRepeat
			let expectedMeasure = measureRepeat.expand()[1]
			XCTAssertNotNil(expectedMeasure as? RepeatedMeasure)
			XCTAssertEqual(repeatedMeasure as? RepeatedMeasure, expectedMeasure as? RepeatedMeasure)
		} catch {
			XCTFail(String(error))
		}
	}
	
	// MARK: - measureRepeatAtIndex(_: Int) -> MeasureRepeat
	// MARK: Failures
	
	func testMeasureRepeatAtIndexForInvalidIndexNegative() {
		do {
			let _ = try staff.measureRepeatAtIndex(-1)
			shouldFail()
		} catch StaffError.MeasureIndexOutOfRange {
		} catch {
			expected(StaffError.MeasureIndexOutOfRange, actual: error)
		}
	}
	
	func testMeasureRepeatAtIndexForInvalidIndexTooLarge() {
		do {
			let _ = try staff.measureRepeatAtIndex(staff.notesHolders.count + 10)
			shouldFail()
		} catch StaffError.MeasureIndexOutOfRange {
		} catch {
			expected(StaffError.MeasureIndexOutOfRange, actual: error)
		}
	}
	
	func testMeasureRepeatAtIndexForMeasureNotPartOfRepeat() {
		do {
			let _ = try staff.measureRepeatAtIndex(1)
			shouldFail()
		} catch StaffError.MeasureNotPartOfRepeat {
		} catch {
			expected(StaffError.MeasureNotPartOfRepeat, actual: error)
		}
	}
	
	// MARK: Successes
	
	func testMeasureRepeatAtIndexForFirstMeasureThatIsRepeated() {
        do {
            let measureRepeat = try staff.measureRepeatAtIndex(5)
            let expected = staff.notesHolders[5] as! MeasureRepeat
            XCTAssertEqual(measureRepeat, expected)
        } catch {
            XCTFail(String(error))
        }
	}
	
	func testMeasureRepeatAtIndexForSecondMeasureThatIsRepeated() {
        do {
            let measureRepeat = try staff.measureRepeatAtIndex(8)
            let expected = staff.notesHolders[7] as! MeasureRepeat
            XCTAssertEqual(measureRepeat, expected)
        } catch {
            XCTFail(String(error))
        }
	}
	
	func testMeasureRepeatAtIndexForRepeatedMeasureInFirstRepeat() {
        do {
            let measureRepeat = try staff.measureRepeatAtIndex(6)
            let expected = staff.notesHolders[5] as! MeasureRepeat
            XCTAssertEqual(measureRepeat, expected)
        } catch {
            XCTFail(String(error))
        }
	}
	
	func testMeasureRepeatAtIndexForRepeatedMeasureInSecondRepeat() {
        do {
            let measureRepeat = try staff.measureRepeatAtIndex(12)
            let expected = staff.notesHolders[7] as! MeasureRepeat
            XCTAssertEqual(measureRepeat, expected)
        } catch {
            XCTFail(String(error))
        }
	}
}
