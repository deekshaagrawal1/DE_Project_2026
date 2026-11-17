CREATE SCHEMA duolingo;
SET search_path TO duolingo;

CREATE TABLE languages (
    language_code VARCHAR(2) PRIMARY KEY,
    language_name VARCHAR(60) NOT NULL UNIQUE,
    CONSTRAINT chk_language_code
        CHECK (language_code ~ '^[a-z]{2}$')
);

CREATE TABLE courses (
    course_id INTEGER PRIMARY KEY,
    from_lang VARCHAR(2) NOT NULL
        REFERENCES languages(language_code) ON DELETE RESTRICT,
    learning_lang VARCHAR(2) NOT NULL
        REFERENCES languages(language_code) ON DELETE RESTRICT,
    title VARCHAR(150) NOT NULL,
    launched_on DATE NOT NULL,
    CONSTRAINT uq_course_languages
        UNIQUE (from_lang, learning_lang),
    CONSTRAINT chk_different_languages
        CHECK (from_lang <> learning_lang)
);

CREATE TABLE units (
    unit_id INTEGER PRIMARY KEY,
    course_id INTEGER NOT NULL
        REFERENCES courses(course_id) ON DELETE RESTRICT,
    unit_no SMALLINT NOT NULL,
    title VARCHAR(150) NOT NULL,
    cefr_level VARCHAR(2) NOT NULL,
    CONSTRAINT uq_unit_in_course
        UNIQUE (course_id, unit_no),
    CONSTRAINT chk_unit_number
        CHECK (unit_no > 0),
    CONSTRAINT chk_cefr_level
        CHECK (cefr_level IN ('A1', 'A2', 'B1', 'B2', 'C1'))
);

CREATE TABLE lessons (
    lesson_id INTEGER PRIMARY KEY,
    unit_id INTEGER NOT NULL
        REFERENCES units(unit_id) ON DELETE RESTRICT,
    lesson_no SMALLINT NOT NULL,
    lesson_type VARCHAR(12) NOT NULL,
    xp_value SMALLINT NOT NULL,
    CONSTRAINT uq_lesson_in_unit
        UNIQUE (unit_id, lesson_no),
    CONSTRAINT chk_lesson_number
        CHECK (lesson_no > 0),
    CONSTRAINT chk_lesson_type
        CHECK (lesson_type IN (
            'LEARN', 'PRACTICE', 'STORY', 'LEGENDARY'
        )),
    CONSTRAINT chk_lesson_xp
        CHECK (xp_value > 0)
);

CREATE TABLE learners (
    learner_id INTEGER PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(254) NOT NULL UNIQUE,
    country_code VARCHAR(2) NOT NULL,
    daily_goal_xp SMALLINT NOT NULL,
    subscription VARCHAR(10) NOT NULL,
    referred_by INTEGER
        REFERENCES learners(learner_id) ON DELETE SET NULL,
    joined_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT chk_country_code
        CHECK (country_code ~ '^[A-Z]{2}$'),
    CONSTRAINT chk_daily_goal
        CHECK (daily_goal_xp IN (10, 20, 30, 50)),
    CONSTRAINT chk_subscription
        CHECK (subscription IN ('FREE', 'SUPER', 'MAX')),
    CONSTRAINT chk_no_self_referral
        CHECK (
            referred_by IS NULL
            OR referred_by <> learner_id
        )
);

CREATE TABLE achievements (
    achievement_id INTEGER PRIMARY KEY,
    code VARCHAR(40) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE enrollments (
    learner_id INTEGER NOT NULL
        REFERENCES learners(learner_id) ON DELETE CASCADE,
    course_id INTEGER NOT NULL
        REFERENCES courses(course_id) ON DELETE RESTRICT,
    enrolled_at TIMESTAMPTZ NOT NULL,
    total_xp INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL,
    PRIMARY KEY (learner_id, course_id),
    CONSTRAINT chk_enrollment_xp
        CHECK (total_xp >= 0)
);

CREATE TABLE lesson_attempts (
    attempt_id INTEGER PRIMARY KEY,
    learner_id INTEGER NOT NULL
        REFERENCES learners(learner_id) ON DELETE CASCADE,
    lesson_id INTEGER NOT NULL
        REFERENCES lessons(lesson_id) ON DELETE RESTRICT,
    started_at TIMESTAMPTZ NOT NULL,
    completed_at TIMESTAMPTZ,
    mistakes SMALLINT NOT NULL DEFAULT 0,
    hearts_lost SMALLINT NOT NULL DEFAULT 0,
    xp_earned SMALLINT NOT NULL DEFAULT 0,
    is_perfect BOOLEAN NOT NULL DEFAULT false,
    device VARCHAR(10) NOT NULL,
    CONSTRAINT chk_mistakes
        CHECK (mistakes >= 0),
    CONSTRAINT chk_hearts
        CHECK (
            hearts_lost >= 0
            AND hearts_lost <= mistakes
        ),
    CONSTRAINT chk_attempt_xp
        CHECK (xp_earned >= 0),
    CONSTRAINT chk_attempt_time
        CHECK (
            completed_at IS NULL
            OR completed_at >= started_at
        ),
    CONSTRAINT chk_perfect_attempt
        CHECK (
            NOT is_perfect
            OR mistakes = 0
        ),
    CONSTRAINT chk_unfinished_xp
        CHECK (
            completed_at IS NOT NULL
            OR xp_earned = 0
        ),
    CONSTRAINT chk_device
        CHECK (device IN ('ANDROID', 'IOS', 'WEB'))
);

CREATE TABLE daily_activity (
    learner_id INTEGER NOT NULL
        REFERENCES learners(learner_id) ON DELETE CASCADE,
    activity_date DATE NOT NULL,
    xp INTEGER NOT NULL,
    lessons_completed SMALLINT NOT NULL,
    used_streak_freeze BOOLEAN NOT NULL DEFAULT false,
    PRIMARY KEY (learner_id, activity_date),
    CONSTRAINT chk_daily_xp
        CHECK (xp >= 0),
    CONSTRAINT chk_lessons_completed
        CHECK (lessons_completed >= 0),
    CONSTRAINT chk_freeze_day
        CHECK (
            NOT used_streak_freeze
            OR xp = 0
        )
);

CREATE TABLE league_memberships (
    learner_id INTEGER NOT NULL
        REFERENCES learners(learner_id) ON DELETE CASCADE,
    week_start DATE NOT NULL,
    tier VARCHAR(12) NOT NULL,
    cohort_id INTEGER NOT NULL,
    weekly_xp INTEGER NOT NULL,
    final_rank SMALLINT,
    result VARCHAR(10),
    PRIMARY KEY (learner_id, week_start),
    CONSTRAINT chk_week_monday
        CHECK (EXTRACT(ISODOW FROM week_start) = 1),
    CONSTRAINT chk_tier
        CHECK (tier IN (
            'BRONZE', 'SILVER', 'GOLD',
            'SAPPHIRE', 'RUBY', 'EMERALD',
            'AMETHYST', 'DIAMOND'
        )),
    CONSTRAINT chk_weekly_xp
        CHECK (weekly_xp >= 0),
    CONSTRAINT chk_final_rank
        CHECK (final_rank BETWEEN 1 AND 30),
    CONSTRAINT chk_league_result
        CHECK (result IN (
            'PROMOTED', 'DEMOTED', 'STAYED'
        )),
    CONSTRAINT chk_rank_result_together
        CHECK (
            (final_rank IS NULL) = (result IS NULL)
        )
);

CREATE TABLE learner_achievements (
    learner_id INTEGER NOT NULL
        REFERENCES learners(learner_id) ON DELETE CASCADE,
    achievement_id INTEGER NOT NULL
        REFERENCES achievements(achievement_id) ON DELETE RESTRICT,
    earned_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (learner_id, achievement_id)
);
