#
# Copyright (C) 2013 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe QuizSortables do
  describe ".initialize" do
    before do
    end

    it "should assign the quiz" do
      quiz = Quiz.new
      sortables = QuizSortables.new(:quiz => quiz, :order => [])

      sortables.quiz.should == quiz
    end

    it "should assign the group and quiz" do
      quiz  = stub
      group = stub(:quiz => quiz)

      sortables = QuizSortables.new(:group => group, :order => [])

      sortables.group.should == group
      sortables.quiz.should  == quiz
    end

    it "should build the list of items" do
      group  = QuizGroup.new
      group.id = 234
      groups = [group]

      question  = QuizQuestion.new
      question.id = 123
      questions = stub(:active => [question])

      quiz = stub(:quiz_groups => groups, :quiz_questions => questions)

      order = [{"type" => "group",    "id" => "234"},
               {"type" => "question", "id" => "123"}]

      sortables = QuizSortables.new(:quiz => quiz, :order => order)
      sortables.items.should == [group, question]
    end

    it "should ignore items that dont have valid ids" do
      groups = [QuizGroup.new]
      questions = stub(:active => [QuizQuestion.new])

      quiz = stub(:quiz_groups => groups, :quiz_questions => questions)

      order = [{"type" => "group",    "id" => "234"},
               {"type" => "question", "id" => "123"}]

      sortables = QuizSortables.new(:quiz => quiz, :order => order)
      sortables.items.should == []
    end
  end

  describe "#reorder!" do
    context "for group questions" do
      before do
        @question1  = QuizQuestion.new
        @question1.id = 123

        @question2  = QuizQuestion.new
        @question2.id = 234

        @quiz = stub(:quiz_groups    => [],
                     :quiz_questions => stub(:active => [@question1, @question2]),
                     :mark_edited!    => true)
        @group = Group.new
        @group.stubs(:quiz => @quiz, :id => 999)

        @order = [{"type" => "question", "id" => "234"},
                  {"type" => "question", "id" => "123"}]
        @sortables = QuizSortables.new(:group => @group, :order => @order)
        @sortables.expects(:update_object_positions!)
      end

      it "should update quiz_group_ids of group questions" do
        @question1.expects(:quiz_group_id=).with(@group.id)
        @question2.expects(:quiz_group_id=).with(@group.id)
        @sortables.reorder!
      end
    end

    context "for quiz items" do
      before do
        @group  = QuizGroup.new
        @group.id = 234

        @question  = QuizQuestion.new
        @question.id = 123

        @quiz = stub(:quiz_groups    => [@group],
                     :quiz_questions => stub(:active => [@question]),
                     :mark_edited!    => true)

        @order = [{"type" => "group",    "id" => "234"},
                  {"type" => "question", "id" => "123"}]
        @sortables = QuizSortables.new(:quiz => @quiz, :order => @order)
        @sortables.expects(:update_object_positions!)
      end

      it "should update positions attribute of questions" do
        @group.expects(:position=).with(1)
        @question.expects(:position=).with(2)

        @sortables.reorder!
      end

      it "should update quiz_group_ids of quiz questions" do
        @question.expects(:quiz_group_id=).with(nil)
        @sortables.reorder!
      end

      it "should mark quiz as edited" do
        @quiz.expects(:mark_edited!)
        @sortables.reorder!
      end
    end

  end
end
