# Moises AI Assessment

Coding challenge for the position of iOS Engineer at Moises AI.

- Proposal: build a music player app that searches for songs using the iTunes API. 
- Screens:
  - Splash
  - Home: shows recently played songs; allows searching for songs
  - Song player: plays queue of songs
  - Album details: details and track list for a given album

## Details

### Technical
- iOS 26+
- Platform: iPhone-first
- Third-party dependencies:
  - Alamofire: networking
  - Kingfisher: image caching
- Languages:
  - English
  - French
  - Portuguese
- Accessibility:
  - Dark/light color schemes
  - SwiftUI accessibility modifiers in place

### Must-have requirements (per challenge description)
- ✅ Usage of Swift 6
- ✅ Usage of SwiftUI
- ✅ MVVM architecture pattern
- ✅ Tests implementation
- ✅ API results pagination
  - ⚠️ The iTunes API doesn't actually support pagination, so the app ends up simulating it, for the sake of demonstrating infinite scrolling and page load error handling. Please see `SongSearchService.init(iTunesAPISession:)`.
- ✅ Usage of Swift concurrency
- ✅ Cache using SwiftData:
  - Recently played songs
  - Search results
  - Album details
- ✅ Network abstraction layer

### Notes
- I've deliverately chosen to mimic some behavior seem in macOS' Music app:
  - The main screen's listing starts with some local content (in this case, the list of recently played songs) and, when the search bar receives focus, the content is immediately replaced by the search results list (which starts off with a placeholder).
  - When a song fails to load, skips to the next one, instead of alerting the user.
    - It wouldn't be hard to alert the user, if required, though: the code necessary for such is already there.
- There are three repeat modes:
  - None (default): plays one song after another, loading more (if available). Pauses when there are no more songs to load.
  - Current: plays the same song indefinitely.
  - All: plays one song after another, loading more (if available). Restarts from the first one when it reaches last song is played

# Running the app

The app was developed with Xcode 26.3 and targets iOS 26 and above.

Running the app in the Simulator should require no setup. Running it on a device may require the usual setup for running an app on a device, which may include having to change the app's Team and Bundle Identifier, and trusting the developer over at Settings -> General -> VPN and device management -> Developer apps.

The apps's main and only test plan includes tests for the everything under and except the View layer (below) and doesn't require any setup.

## Architecture

The app adopts a hierarchical architecture with three main functional layers (top to bottom):
- Views
- View Models
- Services

Each layer is only aware of the layer directly below it and it does so only via some kind of interface, the implementation of which is decided from outside it. 

In addition to the main layers, there are also Models and Controllers, which appear across all layers.

Lastly, the app also adopts Inversion of Control, so every major function of the app is abstracted in some way and which implementation will be used in a given moment is outside the control of the dependee.

### Models

Definitions of the main types used throughout the app.

Types at the root of the `Models` directory (`Song`, `Album`, `SongInteraction`) are meant to be the business-logic-relevant types - those used by the app to do what it's meant to do.

Types in the `API` and `Storage` directories are meant to be used only by the `Services` layer (below), in what regards communication with the API and SwiftData storage, respectively. These types will be very similar to the business-logic-relevant ones, but because they serve different, narrower purposes, it's safer to keep them as separate things and map one to another when required.

### Services

Services manage access to the data, however that is done (e.g., API request, cache, or combination of cache + API).

They are ignorant of UI and (except for events which they may trigger) stateless. As such, they are defined as `struct` and their are functions declared as `var`. This allows us to easily implement and mock them, without resorting to protocols and different implementation `struct`/`class`s.

`SongSearchService` and `AlbumSearchService` have several different "implementations" (i.e. different instances of the service with different values for the function `var`s):
- `iTunes`: gets data via request to the iTunes API
- `cache`: gets data from SwiftData storage
- `hybrid`: mixes `cache` and `iTunes` - if the data isn't found in the `cache`, or has expired, requests it from `iTunes` and saves it to the `cache`.

### View Models

The main layer of the app: it controls the business logic by acquiring data to be displayed and handling user interaction.

There are view models for each main screen of the app (above), as well as to repeatable pieces of business logic:
- Paginated list with refresh
- View presentation

Each view model will have a corresponding `View` or view modifier which will connect/respond to its properties and call its methods on user interaction.

Each view model is defined in two "phases":
- Protocol: describes the general behavior expected from a view model
- Implementation: implements the View Model protocol to provide actual functionality

### Views

Views present/format data provided by the View Models to the user and pass user interaction to them. 

Although under SwiftUI all visible elements are implementations of the `View` protocol, we still separate them into:
- `Screens`: full-screen views that correspond to main app features
- `Components`: reusable visual elements

For the most part, Views don't really have any involved programming logic and just take care of presenting the data provided by the View Models. There are, however, some cases where the very presentation of that data requires some slightly involved programming; since this is a presentation matter and, in thesis, doesn't necessarily relate to business logic, it's done in the Views themselves.

### Controllers

Controllers abstract supporting pieces of business logic that are not Services nor View Models. They are ignorant of anything other than the specific function they serve and, as such, are used by Services and View Models alike.

Except for `Event`, which is simple enough that mock implementations would end up like the actual one, controllers are also defined in two phases: protocol and implementation.

### Inversion of Control

IoC is implemented via a protocol, `IoCContainer`, with functions to provide each type of dependency in the app: Services, View Models, and Controllers.

An instance of `IoCContainer` is passed arround such that, when some piece of code requires one of the dependencies, it asks the container for it, instead of manually instantiating something.

An extension to `IoCContainer` provides default implementations to the protocol's methods, return the actual dependencies used by the app, but tests (as well as other, not-currently-existing circumstances, e.g.: different platform) can create they own `IoCContainer` that returns mock implementations and the like.

## On the use of AI

For the first couple days of development, for the largest part, I did everything myself, using AI only to solve the occasional question or help me with some error. During this time, I laid out the most important parts of the app: the three main features of the app (song list, song player, album details), the main layers and their responsibilities, and the bulk of the UI.

Once I was sufficiently satisfied with the way things had been established and had a clear vision of what was going to be necessary to finish the project, I started using AI (Codex) extensively to help me with code refactoring and review, implementation of structural improvements, and, most importantly, automated tests.

Some files were authored by Codex and bear its name as author; in the interest of honesty I've chosen not to change that, though I've always reviewed those files (the Lord knows I had to, otherwise the code wouldn't compile or some tests wouldn't be passing).

## Areas of improvement
- UI tests
- Proper iPad support (in the Figma, but not required)
- watchOS and CarPlay support (in the Figma, but not required)