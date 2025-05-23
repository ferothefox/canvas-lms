/*
 * Copyright (C) 2024 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React from 'react'
import {render} from '@testing-library/react'
import GettingStartedCollaborations from '../GettingStartedCollaborations'

describe('GettingStartedCollaborations', () => {
  function setEnvironment(roles, context) {
    ENV.context_asset_string = context
    ENV.current_user_roles = roles
    ENV.CREATE_PERMISSION = true
  }

  test('renders the Getting Startted app div', () => {
    setEnvironment([], 'course_4')
    const wrapper = render(
      <GettingStartedCollaborations ltiCollaborators={{ltiCollaboratorsData: ['test']}} />,
    )
    expect(wrapper.container.querySelectorAll('.GettingStartedCollaborations')).toHaveLength(1)
  })

  test('renders the correct content with lti tools configured as a teacher', () => {
    setEnvironment(['teacher'], 'course_4')
    const wrapper = render(
      <GettingStartedCollaborations ltiCollaborators={{ltiCollaboratorsData: ['test']}} />,
    )
    const expectedHeader = 'Getting started with Collaborations'
    const expectedContent =
      'Collaborations are web-based tools to work collaboratively on tasks like taking notes or grouped papers. Get started by clicking on the "+ Collaboration" button.'
    const expectedLinkText = 'Learn more about collaborations'

    expect(expectedHeader).toEqual(
      wrapper.container.querySelector('.ic-Action-header__Heading').textContent,
    )
    expect(expectedContent).toEqual(wrapper.container.querySelector('p').textContent)
    expect(expectedLinkText).toEqual(wrapper.container.querySelector('a').textContent)
  })

  test('renders the correct content with no lti tools configured data as a teacher', () => {
    setEnvironment(['teacher'], 'course_4')
    const wrapper = render(
      <GettingStartedCollaborations ltiCollaborators={{ltiCollaboratorsData: []}} />,
    )
    const expectedHeader = 'No Collaboration Apps'
    const expectedContent =
      'Collaborations are web-based tools to work collaboratively on tasks like taking notes or grouped papers. Get started by adding a collaboration app.'
    const expectedLinkText = 'Learn more about collaborations'

    expect(expectedHeader).toEqual(
      wrapper.container.querySelector('.ic-Action-header__Heading').textContent,
    )
    expect(expectedContent).toEqual(wrapper.container.querySelector('p').textContent)
    expect(expectedLinkText).toEqual(wrapper.container.querySelector('a').textContent)
  })

  test('renders the correct content with no collaborations data as a student', () => {
    setEnvironment(['student'], 'course_4')
    const wrapper = render(
      <GettingStartedCollaborations ltiCollaborators={{ltiCollaboratorsData: []}} />,
    )
    const expectedHeader = 'No Collaboration Apps'
    const expectedContent =
      'You have no Collaboration apps configured. Talk to your teacher to get some set up.'

    expect(expectedHeader).toEqual(
      wrapper.container.querySelector('.ic-Action-header__Heading').textContent,
    )
    expect(expectedContent).toEqual(wrapper.container.querySelector('p').textContent)
  })

  test('renders the correct content with lti tools configured as a student with create permission enabled', () => {
    setEnvironment(['student'], 'course_4')
    const wrapper = render(
      <GettingStartedCollaborations ltiCollaborators={{ltiCollaboratorsData: ['test']}} />,
    )
    const expectedHeader = 'Getting started with Collaborations'
    const expectedContent =
      'Collaborations are web-based tools to work collaboratively on tasks like taking notes or grouped papers. Get started by clicking on the "+ Collaboration" button.'
    const expectedLinkText = 'Learn more about collaborations'

    expect(expectedHeader).toEqual(
      wrapper.container.querySelector('.ic-Action-header__Heading').textContent,
    )
    expect(expectedContent).toEqual(wrapper.container.querySelector('p').textContent)
    expect(expectedLinkText).toEqual(wrapper.container.querySelector('a').textContent)
  })

  test('renders the correct content with lti tools configured as a student with create permission disabled', () => {
    setEnvironment(['student'], 'course_4')
    ENV.CREATE_PERMISSION = false

    const wrapper = render(
      <GettingStartedCollaborations ltiCollaborators={{ltiCollaboratorsData: ['test']}} />,
    )
    const expectedHeader = 'Getting started with Collaborations'
    const expectedContent =
      'Collaborations are web-based tools to work collaboratively on tasks like taking notes or grouped papers. Talk to your teacher to get started.'
    const expectedLinkText = 'Learn more about collaborations'

    expect(expectedHeader).toEqual(
      wrapper.container.querySelector('.ic-Action-header__Heading').textContent,
    )
    expect(expectedContent).toEqual(wrapper.container.querySelector('p').textContent)
    expect(expectedLinkText).toEqual(wrapper.container.querySelector('a').textContent)
  })
})
